class Report < ::ActiveRecord::Base

  include ::Filters::ContentType

  attr_accessible :offender_user_id, :reporter_user_id, :resolver_user_id, :content_type, :content_type_id, :reason_type,
                  :reason_message, :resolution_level

  attr_accessor :notification

  # Associations
  belongs_to :offender, foreign_key: 'offender_user_id', class_name: 'User'
  belongs_to :reporter, foreign_key: 'reporter_user_id', class_name: 'User'
  belongs_to :resolver, foreign_key: 'resolver_user_id', class_name: 'User'


  # All types, both child and parent
  object_constants :reason_type, :being_mean, :bad_words, :picture, :not_allowed, :invalid_user, :offensive_item, :personal_info, :harassment_abusive, :other
  REASON_TYPES_CHILD = { 'BEING_MEAN' => 'Being Mean', 'BAD_WORDS' => 'Bad Words', 'PICTURE' => 'Picture', 'NOT_ALLOWED' => 'Not Allowed',
                         'INVALID_USER' => 'Invalid User', 'OTHER' => 'Other' }
  REASON_TYPES_PARENT = { 'OFFENSIVE_ITEM' => 'Offensive Item', 'NOT_ALLOWED' => 'Not Allowed', 'PERSONAL_INFO' => 'Personal Info',
                          'HARASSMENT_ABUSIVE' => 'Harassment/Abusive' }

  object_constants :status, :pending_parent_action, :pending_admin_action, :pending_repost_approval, :reposted, :deleted_by_parent, :deleted_by_admin

  STATUSES.each do |s|
    define_method "#{s.downcase}?" do
      status.to_s.upcase == "#{s}"
    end
  end
  PENDING_STATUSES = [Status::PENDING_PARENT_ACTION, Status::PENDING_ADMIN_ACTION, Status::PENDING_REPOST_APPROVAL]
  COMPLETED_STATUSES = [Status::REPOSTED, Status::DELETED_BY_PARENT, Status::DELETED_BY_ADMIN]

  ###############
  # Scopes

  scope :pending, conditions: { status: PENDING_STATUSES }
  scope :completed, conditions: { status: COMPLETED_STATUSES }
  scope :time_to_extend_blocks, conditions: "NOW() > DATE_ADD(created_at, INTERVAL 3 DAY) AND NOW() < DATE_ADD(created_at, INTERVAL 7 DAY)"


  before_save :set_defaults
  before_create :check_user_background
  after_create :suspend_content_record!, :block_users!, :create_notifications!
  after_update :handle_notifications!

  validate :check_attributes
  validates_presence_of :offender_user_id, :content_type_id



  def viewable_by_user?(user)
    user.is_a?(Admin) || [offender_user_id, reporter_user_id].include?(user.id) || user.parent_of?(offender) || user.parent_of?(reporter)
  end

  ##
  # Parent can repost when status=pending_parent_action;
  def repostable_by_user?(user)
    user.is_a?(Admin) || ( user.parent_of?(offender) && pending_parent_action? )
  end

  def deleteable_by_user?(user)
    user.is_a?(Admin) || user.parent_of?(offender)
  end

  def completed?
    COMPLETED_STATUSES.include?(status)
  end

  def as_json(options = {})
    report_h = super(options.merge(only: [:id, :offender_user_id, :reporter_user_id, :resolver_user_id, :content_type, :content_type_id,
                                          :reason_type, :reason_message, :status, :secondary_filter_severity, :resolved, :resolution_level,
                                          :created_at, :resolved_at],
                                   methods: [:offender, :reporter, :resolver]) )
    report_h['type'] = self.content_type
    record = self.content_record
    if record.is_a?(Item)
      report_h['item'] = record.as_json
    elsif record.is_a?(ItemComment)
      report_h['comment'] = record.as_json
    elsif record.is_a?(::Trade::TradeComment)
      report_h['trade_comment'] = record.as_json
    end
    report_h
  end

  ##
  # @return <bool>
  def self.valid_reason_type?(reason_type)
    REASON_TYPES.collect(&:to_s).include?(reason_type.to_s.upcase)
  end



  ##
  # user <User or its subclass>  So Admin class
  def self.for_user(user)
    where( "`reports`.`offender_user_id`= #{user.id} OR `reports`.`reporter_user_id`= #{user.id}" ).all
  end

  ##################################
  # Management Actions

  ##
  # @return <boolean> whether record suspended
  def suspend_content_record!
    record = self.content_record
    if record.is_a?(Item) && record.open?
      if offender.new_user?
        logger.info "| New user #{offender.user_name} needs all #{Item.owned_by(offender).count} items suspended"
        Item.owned_by(offender).update_all(status: ::Item::Status::REPORT_SUSPENDED)

      else # Single item
        record.status = ::Item::Status::REPORT_SUSPENDED
        logger.info "  Item(#{record.id}) status => #{record.status}"
        record.save
      end
    elsif record.is_a?(::Trading::TradeComment)
      record.status = ::Trading::TradeComment::Status::REPORT_SUSPENDED
      logger.info "  TradeComment(#{record.id}) status => #{record.status}"
      record.save

    else
      false
    end
  end

  ##
  #
  def restore_content_record!
    record = self.content_record
    if record.is_a?(Item) && record.suspended?
      record.status = ::Item::Status::OPEN
      logger.info "  Item(#{record.id}) status => #{record.status}"
      record.save

    elsif record.is_a?(::Trading::TradeComment)
      record.status = ::Trading::TradeComment::Status::REPLIED
      logger.info "  TradeComment(#{record.id}) status => #{record.status}"
      record.save

    else
      false
    end
  end

  ##
  # options <Hash> Report attributes
  # @return <boolean> whether successfully reposted
  def repost_by!(user, options = {} )
    options ||= {}
    if user.is_a?(Admin)
      self.status = Status::REPOSTED
      self.resolved = true
      self.resolved_at = Time.now
      self.resolver_user_id = user.id
      self.resolution_level = options[:resolution_level]
      self.reason_type = options[:reason_type] if options[:reason_type].present?
      self.reason_message =  options[:reason_message] if options[:reason_message].present?
      self.save

      ::Users::UserBlock.remove_from_user_blocks!(reporter_user_id, offender.family_user_ids)

      self.restore_content_record!

    elsif self.repostable_by_user?(user)
      self.status = Status::PENDING_REPOST_APPROVAL
      self.save

    else
      false
    end
  end

  # @return <boolean> whether successfully deleted
  def delete_by!(user, options = {} )
    options ||= {}

    record = self.content_record
    if record.is_a?(Item) && record.suspended?
      record.status = ::Item::Status::REPORT_DELETED
      logger.info "  Item(#{record.id}) status => #{record.status}"
      record.save

    elsif record.is_a?(::Trading::TradeComment)
      record.status = ::Trading::TradeComment::Status::REPLIED
      logger.info "  TradeComment(#{record.id}) status => #{record.status}"
      record.save
    end

    self.resolved = true
    self.resolved_at = Time.now
    if user.is_a?(Admin)
      self.status = ::Report::Status::DELETED_BY_ADMIN
      self.resolver_user_id = user.id
      self.resolution_level = options[:resolution_level]
      self.reason_type = options[:reason_type] if options[:reason_type].present?
      self.reason_message =  options[:reason_message] if options[:reason_message].present?
      self.save

    else
      self.status = ::Report::Status::DELETED_BY_PARENT
      self.save
    end
  end

  ##
  def block_users!

    offender.reported_count = ::Report.where(offender_user_id: offender_user_id).count
    offender.save

    reporter.reporter_count = ::Report.where(reporter_user_id: reporter_user_id).count
    reporter.save
    reporter.family_user_ids.each do|reporter_family_user_id|
      ::Users::UserBlock.add_to_user_blocks!(reporter_family_user_id, offender.family_user_ids )
    end
  end

  ##
  # Sets the other side (offender) to have users blocked.
  def block_both_sides_of_users!
    # block_users! # This would ensure reporter's side has blocks made
    offender.family_user_ids.each do|offender_family_user_id|
      ::Users::UserBlock.add_to_user_blocks!(offender_family_user_id, reporter.family_user_ids )
    end
  end

  ##
  def create_notifications!
    unless self.pending_admin_action? # regular level
      conds = { recipient_user_id: (offender.parent_id || offender.parent.id),
                related_model_type: 'Report', related_model_id: self.id }
      n = ::Users::Notification.where(conds).first
      n ||= ::Users::Notifications::ChildReported.create( conds.merge(sender_user_id: offender_user_id) )
      self.notification = n
    end

  end

  def clear_notifications!
    ::Users::Notification.where(
        type:['Users::Notifications::ChildReported', 'Users::Notifications::ReportedChild'], related_model_type: 'Report', related_model_id: self.id ).
        update_all(status: 'DELETED')
  end

  ##
  # Review over pending reports within the time range for extending user blocks

  def self.review_pending_reports
    total_pending_count = pending.time_to_extend_blocks.count
    puts "# #{total_pending_count} found within time for extending user blocks"

    if total_pending_count > 0
      # Use of fresh query of records instead of iterating over same condition's limits/pages
      limit = 20
      report_run_count = 0
      current_report_id = ::Report.pending.time_to_extend_blocks.order('id asc').select('id').first.id
      while ( list = ::Report.pending.time_to_extend_blocks.where("id >= #{current_report_id}").limit(limit) ).present?
        list.each do|report|
          puts "| Report(#{report.id}) - block both sides (reporter #{report.reporter_user_id}, offender #{report.offender_user_id})"
          report.block_both_sides_of_users!
        end
        current_report_id = list.last.id
        report_run_count += limit # This avoids faulty queries causing infinite loop
        if report_run_count > total_pending_count
          break
        end
      end
    end
  end

  protected

  def set_defaults
    self.resolved = false if self.resolved.nil?
    self.reason_type = ReasonType::OTHER if not self.class.valid_reason_type?(reason_type)
    self.status = Status::PENDING_PARENT_ACTION if self.status.blank? || !STATUSES.include?(self.status.upcase.to_sym)
  end

  ##
  # Check whether user is new, so to esculate status.
  def check_user_background
    self.status = Status::PENDING_ADMIN_ACTION if offender && offender.new_user?
  end


  ##
  # If report ended, clear notifications
  def handle_notifications!
    if completed?
      self.clear_notifications!
    end
  end
end
