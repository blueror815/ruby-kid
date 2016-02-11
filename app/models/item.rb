class Item < ActiveRecord::Base

  include ::NotificationHandler
  include ::Items::ItemInfo

  attr_accessible :description, :price, :title, :quantity, :category_id, :item_photos_attributes, :item_keywords_string,
                  :gender_group, :age_group, :intended_age_group, :updated_at
  attr_accessor :category_id, :item_keywords_string, :active_trade, :active_trade_json, :active_buy_request

  belongs_to :user
  alias_attribute :owner, :user

  has_many :item_photos, order: 'id asc', :dependent => :destroy
  accepts_nested_attributes_for :item_photos, :reject_if => :all_blank, :allow_destroy => true

  has_and_belongs_to_many :categories
  has_many :item_keywords, :dependent => :destroy

  has_and_belongs_to_many :trades, class_name: 'Trading::Trade', :join_table => 'trades_items'
  has_many :trade_items, class_name: 'Trading::TradeItem'

  has_and_belongs_to_many :buy_requests, class_name: 'Trading::BuyRequest', :join_table => 'buy_requests_items'
  has_many :buy_request_items, class_name: 'Trading::BuyRequestItem'

  has_many :item_comments, :dependent => :destroy
  has_many :associated_categories, :dependent => :destroy

  extend Forwardable
  def_delegators :user, :current_school, :current_school_id, :user_name, :name, :gender, :teacher, :grade, :profile_image_url

  ##################
  # Constants

  searchable(:if => :open_for_search?) do
    integer :user_id
    integer :category_ids, :multiple => true
    integer :associated_categories, :multiple => true
    text :title, :more_like_this => true
    text :description, :more_like_this => true
    text :keywords, :more_like_this => true do
      item_keywords.collect { |kw| kw.keyword + ' ' }
    end
    float :price
    integer :school_id do
      current_school_id
    end
    string :teacher
    integer :grade
    string :gender do
      gender.present? ? gender[0].upcase : '' # owner's gender character M or F
    end
    string :gender_group, multiple: true do
      gender_group.blank? ? ['M', 'F'] : gender_group.chars.to_a
    end
    integer :gender_group_order do
      Item.gender_group_order_score( gender_group )
    end
    string :age_group
    time :activated_at
  end

  object_constants :status, :draft, :pending, :open, :trading, :buying, :ended, :declined, :report_deleted, :report_suspended, :pending_account_confirmation
  object_constants :intended_age_group, :same, :all_ages, :younger, :older

  ACTIVE_STATUSES = [Status::OPEN, Status::TRADING, Status::BUYING]

  PENDING_ITEM_TITLE = 'Wants to Post This Item'

  self.per_page = 20

  ##################
  # Scopes

  scope :open_items, where(status: Status::OPEN )
  scope :active, where(["status IN (?)", ACTIVE_STATUSES] )
  scope :pending_approval, where("status IN (?)", [Status::PENDING])
  scope :pending, where("status IN (?)", [Status::PENDING, Status::PENDING_ACCOUNT_CONFIRMATION])
  scope :inactive, where("status IN (?)", [Status::ENDED, Status::PENDING, Status::DRAFT])
  scope :declined, where(status: Status::DECLINED)
  scope :pending_account_confirmation, where(status: Status::PENDING_ACCOUNT_CONFIRMATION)
  scope :pending_then_open, lambda {
    where(status: ACTIVE_STATUSES + [Status::PENDING, Status::PENDING_ACCOUNT_CONFIRMATION]).order('status desc, id asc')
  }
  scope :owned_by, lambda { |user|
    user.is_a?(Parent) ?
      where("user_id IN (?)", [user.id] + user.children.select("secondary_user_id").collect(&:secondary_user_id)) :
      where("user_id = ?", user.id)
  }

  ##################

  validates_presence_of :price
  validate :check_categories

  before_save :validate_attributes, :set_associations!, :limit_item_photos!
  after_save :update_user_info!
  after_save :check_for_association_async!


  def initialize(params = {})
    self.category_id = params.delete(:category_id)
    super(params.select{|k,v| ![:item_photos, :item_photos_attributes, :location].include?(k.to_sym) } )

    set_associations!
    self
  end

  def clear_item_photos!(exclude_item_photo_ids = [])
    logger.info "-- cleaning up existing item_photos(#{self.item_photos.size}) 1st ------------------- exclude list #{exclude_item_photo_ids} "

    self.item_photos.each do|p|
      puts "  item_photo %4d | #{exclude_item_photo_ids.include?(p.id)}"
      next if exclude_item_photo_ids.include?(p.id)
      p.destroy
    end
    self.item_photos.reload
  end

  def load_item_photos_with_params(params)
    item_photos = params[:item_photos] || params[:item_photos_attributes]
    # Problem caused by nested form where "item_photo_attributes"=>{"someuniqkey"=>{"name"=>"", "image"=>#<ActionDispatch::Http::UploadedFile:0x007f>} }
    if item_photos.is_a?(Hash) && item_photos.values.all?{|v| v.is_a?(Hash) }
      item_photos = item_photos.values
    end

    any_change_to_photos = false # This would lead to deletion of existing ones
    old_item_photos = self.item_photos.clone

    if item_photos.is_a?(Array)
      item_photos.each_with_index do|p, item_index|
        begin
          image_file = nil #
          filename = nil
          if p.is_a?(Hash)
            logger.info "  + photo hash: #{p}"
            filename = p[:name]
            if (url = p[:url] ).present?
              self.default_thumbnail_url ||= url if self.default_thumbnail_url.blank?
              if filename.blank?
                filename = File.basename(url)
                filename << '.jpg' if filename.match(/\.(png|jpg|jpeg)$/i).nil?
              end
              # See if matched to old photo
              photo = old_item_photos.find{|old_photo| (old_photo.remote_image_url || old_photo.image_url) == url }
              unless photo
                photo = ItemPhoto.new(item_id: self.id, name: filename, default_photo: item_index.zero?, width: p[:width].to_i, height: p[:height].to_i )
                photo.remote_image_url = url
                self.item_photos << photo
                any_change_to_photos = true
              end

            end
            image_file ||= p[:image] # direct assignment of an image file object

          elsif p.is_a?(ActionDispatch::Http::UploadedFile)
            image_file = p
          end

          if image_file.is_a?(ActionDispatch::Http::UploadedFile) # File
            logger.info "  + photo file: #{image_file.original_filename}"
            photo = ItemPhoto.new(item_id: self.id, name: filename || image_file.original_filename, default_photo: item_index.zero?)
            photo.image = image_file
            self.item_photos << photo
          end
        rescue Exception => photo_e
          logger.warn "   ** Problem adding photo: #{photo_e.message}: " + photo_e.backtrace.join("\n")
        end
      end
    end # item_photos.is_a?(Array)

    if any_change_to_photos && old_item_photos.present?
      old_item_photos.each do|photo|
        if not photo.new_record?
          photo.destroy
        end
      end
    end
  end

  def validate_attributes
    if self.price.to_f < 0.01
      self.errors.add(:price, "Price of the item is required")
    end
  end

  ##
  # Extended checks and attribute settings depending on user
  # @editor <User> If not specified, would be the attribute self.user
  def set_by_user(editor = nil)
    editor ||= self.user
    return false if editor.nil?
    if ( !REQUIRES_PARENT_APPROVAL || editor.parent_of?(self.user) )
      set_to_activate

    else
      self.status = (REQUIRES_PARENT_APPROVAL || status.blank?) ? Status::PENDING : Status::OPEN
    end
    true
  end

  # Does the setting for an item to be activated.  But does not save item.
  def set_to_activate
    if REQUIRES_ACCOUNT_CONFIRMATION_TO_ACTIVATE && owner.parent && !owner.parent.account_confirmed
      self.status = Status::PENDING_ACCOUNT_CONFIRMATION
    elsif owner.requires_parental_guidance? && owner.parent.nil?
      self.status = Status::PENDING
    else
      self.status = Status::OPEN
      owner.update_friends_new_item
    end
    self.activated_at = Time.now
  end

  def activate!
    set_to_activate
    self.save
    if self.owner.parent && (REQUIRES_ACCOUNT_CONFIRMATION_TO_ACTIVATE == false || self.owner.parent.account_confirmed)
      self.remove_related_notifications!
    end
  end

  def deactivate!
    self.status = Status::ENDED
    save
    self.remove_related_notifications!
  end

  def decline!
    self.status = Status::DECLINED
    self.save
    self.remove_related_notifications!
  end


  ####################
  # Class methods

  def self.gender_group_order_score(gender_group)
    if gender_group.blank? || gender_group.upcase == 'MF'
      5
    elsif gender_group.upcase == 'F'
      9
    else
      0
    end
  end

  #will return the same searching information

  # ==== Parameters
  # @search_params may be same parameters params from request or added with options
  #   :school_id
  #
  # @current_user <User>
  #
  # ==== Returns
  #   <Sunspot::Search>
  def self.build_search(search_params, current_user = nil)
    search = Sunspot.new_search(Item) do
      paginate :page => search_params[:page] || 1, :per_page => Item.per_page
      if not current_user.nil?
        without :user_id, current_user.id
      end
    end

    search_params[:query] = search_params[:q] if search_params[:query].blank? && search_params[:q]
    if search_params[:query].present?
      search_params[:query] = CGI.unescape(search_params[:query])
      search.build do
        fulltext search_params[:query].strip do
          boost_fields :title => 2.0, :keywords => 1.5
        end
      end
    end

    if search_params[:category_id].present? && (@category = Category.find_by_id(search_params[:category_id].to_i))
      search.build do
        any_of do
          with :category_ids, search_params[:category_id].to_i
          with :associated_categories, search_params[:category_id].to_i
        end
      end
    end

    if current_user
      search.build do
        if search_params[:action].to_s == 'friends' # Followers
          with :user_id, current_user.followings.collect(&:user_id)

        elsif current_user.is_a?(Child)
          user_ids_to_exclude = [current_user.id]
          current_user.boundaries.group_by(&:type).each do|btype, blist|
            case btype
              when 'Users::UserBlock'
                user_ids_to_exclude = user_ids_to_exclude + ::Users::Boundary.extract_content_values_from_list(blist)
            end
          end
          any_of do
            all_of do
              without :user_id, user_ids_to_exclude
              with :school_id, current_user.current_school_id
              current_user.boundaries.group_by(&:type).each do|btype, blist|
                case btype
                  when 'Users::ChildCircleOption'
                    case blist.first.content_keyword
                      when 'ONE_GRADE_AROUND'
                        with :grade, ::Schools::SchoolGroup.grades_around(current_user.grade) if current_user.grade
                      when 'GRADE_ONLY'
                        with :grade, current_user.grade if current_user.grade
                      when 'CLASS_ONLY'
                        with :teacher, current_user.teacher if current_user.teacher.present?
                    end
                  #---------------------
                  when 'Users::CategoryBlock'
                    without :category_ids, ::Users::Boundary.extract_content_values_from_list(blist)

                  #---------------------
                end
              end
              if search_params[:near_by_school_ids].present?
                with :school_id, search_params[:near_by_school_ids]

              elsif search_params[:school_id]
                with :school_id, search_params[:school_id]
              end
            end
            if not current_user.followings.empty?
              all_of do
                with :user_id, current_user.followings.collect(&:user_id)
                without :user_id, user_ids_to_exclude ######### current_user.is_a?(Parent) ? current_user.children.collect(&:id) : [current_user.id]
              end
            end
          end
        end

        gender_order = current_user.female? ? :asc : :desc
        order_by :gender, gender_order
        order_by(:price, :desc)
      end
    end
    sort = search_params[:sort]
    search.build do
      without :user_id, current_user.id
        order_by sort.split(/\s+/)[0].downcase.to_sym, sort.split(/\s+/)[1].downcase.to_sym
    end if sort.present? && ItemsHelper.valid_sort?(sort)

    search
  end

  private

  def check_for_association_async!
    if status_changed? && self.open?
      ::FilterRecordWorker.perform_async(user_id, 'Item', self.id, ['description'])
    end
    ItemDescriptionCheckWorker.perform_async(self.description, self.category_id, self.id)

  rescue Exception => exception
    ::Jobs::ItemDescriptionCheck.new(self.id).enqueue!
  end

  def self.create_association!(item_id, to_associate_id, item_category_id)
    #checks if there already is an association between the two, then creates it if the to_associate_id and
    #item category id aren't the same.
    already_associated = AssociatedCategory.where(item_id: item_id, category_id: to_associate_id)
    if to_associate_id != item_category_id && already_associated.empty?
      new_association = AssociatedCategory.create!(item_id: item_id, category_id: to_associate_id)
    end
  end

  def self.check_desc_for_associations!(string_to_search, category_id, item_id)
    keyword_pairs = CategoryKeyword.all
    keyword_pairs.each do |keyword_pair|
      if string_to_search.downcase.include? keyword_pair.keyword
        Item.create_association!(item_id, keyword_pair.category_id, category_id)
      end
    end
  end

  def check_categories
    set_associations!
    errors.add(:category_id, "Must be selected within some category") if categories.empty?
  end

  def set_associations!
    logger.debug "keywords_group: #{item_keywords_string}"

    set_by_user if new_record?

    if self.category_id.to_i > 0 && (cat = Category.find_by_id(self.category_id))
      self.categories = cat.all_categories_to_top
      @category = cat
    end
    if item_keywords_string.present?
      self.item_keywords = item_keywords_string.split(',').uniq.collect { |kw| ItemKeyword.new(item_id: id, keyword: kw.strip) }
    end
    self.gender_group = 'MF' if self.gender_group.blank?
    if self.intended_age_group.blank?
      self.intended_age_group = IntendedAgeGroup::SAME
    end
    self.intended_age_group.downcase!
    self.age_group = self.age_group.to_s.gsub(/^(ages:\s*)/i, '')
  end

  def limit_item_photos!
    self.item_photos = item_photos[0, ItemPhoto::MAX_ITEM_PHOTOS] if item_photos.present?
  end

  ##
  # Update child's pending item count.
  #
  def update_user_info!
    if REQUIRES_PARENT_APPROVAL
      ::Users::Notifications::IsWaitingForApproval.update_approval_notification!(self.user)
    else
      ::Users::Notifications::ChildNewItem.update_notification!(self)
    end
    self.user.recalculate_item_count!
  end
end
