class ItemComment < ActiveRecord::Base
  attr_accessible :user_id, :recipient_user_id, :item_id, :buyer_id, :body, :parent_id

  belongs_to :item
  belongs_to :sender, class_name: 'User', foreign_key: :user_id
  belongs_to :recipient, class_name: 'User', foreign_key: :recipient_user_id
  belongs_to :buyer, class_name: 'User', foreign_key: :buyer_id
  belongs_to :parent_item_comment, class_name: 'ItemComment', foreign_key: :parent_id

  alias_attribute :sender_user_id, :user_id
  alias_attribute :user, :sender

  object_constants :status, :open, :report_suspended
  STATUSES.each do |s|
    define_method "#{s.downcase}?" do
      status.to_s.upcase == "#{s}"
    end
  end

  ##
  # Scopes
  scope :still_open, conditions:{status: Status::OPEN }

  ##
  # Callbacks
  after_create :create_notification!
  after_create :delete_old_notification!
  after_save :async_filter

  validates_presence_of :item_id, :body

  def is_sender_the_buyer?
    user_id == buyer_id
  end

  def is_sender_the_seller?
    user_id == seller_id
  end

  def seller_id
    is_sender_the_buyer? ? recipient_user_id : user_id
  end

  # Requires both user_id and buyer_id to work.
  # +current_user_id+ <User or integer>
  # @return <integer>
  def the_other_user_id(current_user_id = nil)
    current_user_id = current_user_id.id if current_user_id.is_a?(User)
    (current_user_id == buyer_id) ? seller_id : buyer_id
  end

  def the_other_user(current_user_id = nil)
    User.find(the_other_user_id(current_user_id))
  end

  def as_json(options = nil)
    super( (options || {}).merge(only: [:id, :user_id, :recipient_user_id, :buyer_id, :item_id, :parent_id, :body] ) ).merge(
      user: user.as_more_json({}, recipient_user_id), recipient: recipient.as_more_json({}, sender_user_id), created_at: created_at.utc.to_s(:utc)  )
  end

  private

  def set_default!
    self.status ||= Status::OPEN
  end

  def create_notification!
    logger.info "| created ItemComment(#{self.id}, from parent_id #{self.parent_id}"
    uri = Rails.application.routes.url_helpers.item_comment_path(self)
    klass = if self.parent_id.to_i > 0 then
              is_sender_the_seller? ? ::Users::Notifications::HasAnswer : ::Users::Notifications::HasComment
            else
              ::Users::Notifications::HasComment
            end
    
    #item_comment isn't useful, giving the entire item allows for the whole thread to be loaded in the app.
    notification = klass.create(sender_user_id: user_id, recipient_user_id: recipient_user_id,
                                                uri: uri, related_model_type: Item.to_s, related_model_id: self.item_id)
    ::NotificationMail.create_from_mail(user_id, recipient_user_id, UserMailer.item_comment(self) ) if recipient.email.present?
    notification
  end

  def delete_old_notification!
    if self.parent_id.to_i > 0
      ::Users::Notifications::HasComment.sent_to(user_id).where(related_model_type: 'Item', related_model_id: self.item_id).update_all(status: ::Users::Notification::Status::DELETED)
    end
  end

  def async_filter

    ::FilterRecordWorker.perform_async(user_id, 'ItemComment', self.id, ['body'])
  rescue Exception => exception
    ::Jobs::RecordFilter.new(user_id, 'ItemComment', self.id, ['body']).enqueue!
  end
end
