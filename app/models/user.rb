class User < ActiveRecord::Base

  include ::Users::UserRelationshipHandler

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         :authentication_keys => [:login]

  # This replaces the call of devise :validatable because don't want email required for all diff. types of User
  validates_uniqueness_of :email, case_sensitive: false, allow_blank: true, if: :email_changed?
  validates_format_of     :email, with: Devise.email_regexp, allow_blank: true, if: :email_changed?
  validates_presence_of     :password, on: :create
  validates_confirmation_of :password, on: :create
  validates_length_of       :password, within: Devise.password_length, allow_blank: true

  # Setup accessible (or protected) attributes for your model
  attr_accessible :user_name, :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :gender,
                  :interests, :birthdate, :current_school_id, :teacher, :grade, :profile_image, :profile_image_name,
                  :account_confirmed, :business_card_note_sent, :item_total, :driver_license_image, :driver_license_image_name,
                  :is_test_user, :finished_registering, :is_parent_email

  # Virtual attribute that can be the value of user_name or email, which enables the use of either one as login ID
  attr_accessor :login, :is_mutual_friend, :is_follower

  mount_uploader :profile_image, ::ImageUploader
  mount_uploader :driver_license_image, ::ImageUploader

  object_constants :gender, :male, :female

  AUTO_CONFIRM_ACCOUNT = true

  # Main parent since only one path to add create, so only one parent for a child.
  belongs_to :parent, class_name: 'Parent'
  has_many :user_relationships, :class_name => 'Users::Relationship', :foreign_key => 'primary_user_id', :dependent => :destroy

  has_and_belongs_to_many :children, :join_table => 'user_relationships', :association_foreign_key => 'secondary_user_id',
                          :foreign_key => 'primary_user_id', :conditions => ["relationship_type IN (?)", ::Users::Relationship::PARENTS]
  has_and_belongs_to_many :parents, :join_table => 'user_relationships', :association_foreign_key => 'primary_user_id',
                          :foreign_key => 'secondary_user_id', :conditions => ["relationship_type IN (?)", ::Users::Relationship::PARENTS]
  has_and_belongs_to_many :friends, :class_name => 'User', :join_table => 'user_relationships',
                          :foreign_key => 'primary_user_id', :association_foreign_key => 'secondary_user_id',
                          :conditions => ["`user_relationships`.`relationship_type` = ?", Users::Relationship::RelationshipType::FRIEND]

  belongs_to :primary_user_location, :class_name => 'Users::UserLocation'
  has_many :user_locations, :class_name => 'Users::UserLocation'
  has_many :user_phones, :class_name => 'Users::UserPhone'
  has_many :user_notification_tokens, :class_name => 'Users::UserNotificationToken'
  has_one  :user_tracking, :class_name => 'Users::UserTracking'

  has_and_belongs_to_many :schools, :class_name => 'Schools::School'
  belongs_to :current_school, :class_name => 'Schools::School'

  has_and_belongs_to_many :followers, :join_table => 'followers_users', :class_name => 'User',
                          :association_foreign_key => 'follower_user_id'
  has_many :followings, :class_name => 'Stores::Following', :foreign_key => 'follower_user_id'
  has_many :followed_users, :class_name => 'User', :source => 'user', :through => :followings

  has_many :devices

  has_many :items


  has_many :boundaries, class_name: '::Users::Boundary', foreign_key: 'user_id'

  #has_and_belongs_to_many :blocked_users, class_name: 'User', join_table: 'user_blocks',
  #                        foreign_key: 'user_id', association_foreign_key: 'object_user_id'

  ###########################

  validates_presence_of :first_name
  validates_format_of :first_name, :with => /^[a-z\-\.]+$/i, :message => 'Only these letters are allowed in Name: a-z . -',
                      :if => Proc.new { |user| user.first_name.present? && user.last_name.present? }
  validates_format_of :user_name, :with => /^[\w_\-\.]+$/, :message => 'Only these letters are allowed in User Name: a-z 0-9 . _ -',
                      :if => Proc.new { |user| user.user_name.present? }
  validate :check_invalid_user_name
  validate :check_unique_user_name

  before_create :fix_defaults
  after_create :create_default_boundary
  before_save :normalize_attributes
  after_save :apply_related_changes!
  after_save :check_business_card_parent
  after_save :check_send_join_message


  #############################

  searchable do
    integer :id
    text :type
    text :name
    string :gender
    text :interests
    integer :current_school_id
    string :current_school_teacher do
      teacher
    end
    string :user_name do
      user_name.downcase
    end
    string :state
    integer :grade
  end

  def check_send_join_message
    if self.is_a?(Child) and not self.account_confirmed
      if self.should_contact_parent?
        if self.parent.account_confirmed and self.item_count >= TradeConstants::ITEMS_MIN_THRESHOLD
          User.sidekiq_generate_message_new_to_circle(self.id)
        end
      end
    end
  end

  ##
  # Batch run.
  def self.create_business_card_prompt_kid
    users = User.all
    users.each do |user|
      if user.is_a?(Child)
        prompts = ::Users::Notifications::BusinessCardPromptKid.where(recipient_user_id: user.id, status: "DELETED")
        one_week_ago = DateTime.now - 1.week
        if not prompts.empty?
          if prompts.last.updated_at <= one_week_ago
            note_already_created = ::Users::Notifications::BusinessCardPromptKid.where(recipient_user_id: user.id, status: "WAIT")
            if note_already_created.empty?
              ::Users::Notifications::BusinessCardPromptKid.create(sender_user_id: Admin.cubbyshop_admin.id, recipient_user_id: user.id, uri: '/business_cards/')
            end
          end
        elsif ::Users::Notifications::BusinessCardPromptKid.where(recipient_user_id: user.id, status: "WAIT").empty?
          ::Users::Notifications::BusinessCardPromptKid.create(sender_user_id: Admin.cubbyshop_admin.id, recipient_user_id: user.id, uri: '/business_cards/')
        end
      end
    end
  end

  def state
    if self.is_a?(Child)
      if self.primary_user_location.nil?
        "None"
      else
        self.primary_user_location.state
      end
    else
      "None_Parent"
    end
  end

  def city
    if self.is_a?(Child)
      if self.primary_user_location.nil?
        "Unknown"
      else
        self.primary_user_location.city
      end
    else
      "Unknown"
    end
  end

  def email_required?
    !requires_parental_guidance?
  end

  def requires_parental_guidance?
    false
  end

  ##
  # Whether any child action would need to contact the parent.  This depends on requires_parental_guidance?.
  def should_contact_parent?
    requires_parental_guidance?
  end


  def self.sidekiq_tell_friends_new_stuff(user_id)
    puts "--------sidekiq_tell_friends_new_stuff--------"
    #go through all users, check if they added new items and the note was sent out.
    user = User.find(user_id)
    search = User.search_users_in_circle(user)
    search.execute
    results = search.results
    if results.count > 0
      results.each do |user|
        notes = ::Users::Notifications::FriendNewListing.where(recipient_user_id: user.id, sender_user_id: user_id, status: "DELETED")
        twelve_hours_ago = DateTime.now - 12.hours
        if not notes.empty?
          if notes.last.created_at <= twelve_hours_ago
            note_already_created = ::Users::Notifications::FriendNewListing.where(recipient_user_id: user.id, sender_user_id: user_id, status: "WAIT")
            if note_already_created.empty?
              ::Users::Notifications::FriendNewListing.create(recipient_user_id: user.id, sender_user_id: user_id, uri: "/stores/#{user_id}")
            end
          end
        elsif ::Users::Notifications::FriendNewListing.where(recipient_user_id: user.id, sender_user_id: user_id, status: "WAIT").empty?
          ::Users::Notifications::FriendNewListing.create(recipient_user_id: user.id, sender_user_id: user_id, uri: "/stores/#{user_id}")
        end
      end
    end
  end

  def update_friends_new_item
    UserAddedNewStuffWorker.perform_async(self.id)
  rescue Exception
    ::Jobs::ChildAddedNewStuffMessage.new(self.id).enqueue!
  end

  def self.sidekiq_generate_message_new_to_circle(user_id)

    puts "----------sidekiq_generate_message_new_to_circle-----"
    user = User.find(user_id)
    search = User.search_users_in_circle(user)
    search.execute
    results = search.results
    if results.count > 0 and not user.account_confirmed
      results.each do |user|
        ::Users::Notifications::NewToCircle.create(recipient_user_id: user.id, sender_user_id: user_id, uri: "/stores/#{user.id}")
      end
    end
    user.account_confirmed = true
    user.save
  end


  def self.find_for_database_authentication(conditions={})
    if conditions[:login].present?
      where(email: conditions[:login]).last || where(user_name: conditions[:login]).last
    else
      where(email: conditions[:email]).last || where(user_name: conditions[:user_name]).last
    end
  end

  def self.search_possible_friends(query, request_user, expand_search = false)
    search = Sunspot.new_search(User) do
      without :id, request_user.id
    end

    search.build do
      if expand_search
        without :state, "None_Parent"
        without :state, "None"
      else
        with :state, request_user.state
      end
      with :user_name, query if query.present?
    end
    search.execute
    search
  end

  # ===========================
  # @return <Sunspot::Search>
  def self.search_users_in_circle(user, search_params = {} )
    search = Sunspot.new_search(User) do
      without :id, user.id
      #paginate :page => search_params[:page] || 1, :per_page => User.per_page
    end
    search.build do
      user_ids_to_exclude = [user.id]
      user.boundaries.group_by(&:type).each do|btype, blist|
        case btype
          when 'Users::UserBlock'
            user_ids_to_exclude = user_ids_to_exclude + ::Users::Boundary.extract_content_values_from_list(blist)
        end
      end
      any_of do
        all_of do
          user.boundaries.group_by(&:type).each do |btype, blist|
            case btype
              when 'Users::ChildCircleOption'
                case blist.first.content_keyword
                  when 'ONE_GRADE_AROUND'
                    with :grade, ::Schools::SchoolGroup.grades_around(user.grade) if user.grade
                  when 'GRADE_ONLY'
                    with :grade, user.grade if user.grade
                  when 'CLASS_ONLY'
                    with :current_school_teacher, user.teacher if user.teacher.present?
                end
            end
          end
          without :id, user_ids_to_exclude
          with :current_school_id, user.current_school_id
        end
        #put the user id's of the followers
        if not user.followings.empty?
          all_of do
            with :id, user.followings.collect(&:user_id)
            without :id, user_ids_to_exclude
          end
        end
      end
    end if user.current_school_id.to_i > 0
    search.execute
    search
  end

  def self.search_users_that_like_item(search_params = {})
    search = Sunspot.new_search()
  end

  COMPARABLE_BAD_WORD_REGEX = /^[\w]{3,}$/

  def check_invalid_user_name
    if user_name.present? && user_name_changed?
      ::Obscenity::Base.blacklist.each do|bad_word|
        if bad_word =~ COMPARABLE_BAD_WORD_REGEX && user_name =~ /#{bad_word}/i # all alphanum bad_word
          logger.info "** Invalid user_name #{user_name} vs #{bad_word}"
          self.errors.add(:user_name, "Invalid user ID")
          break
        end
      end
    end
  end

  def check_unique_user_name
    if user_name.present?
      self.errors.add(:user_name, "This user ID is already taken") if user_name_changed? && ( (type != 'Admin' && user_name =~ /^cubby(.{0,2})shop/i) || User.count(conditions: ["user_name=? and id <> ?", user_name, id.to_i]) > 0 )
    end
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login)).present?
      where(conditions).where(["lower(user_name) = :value OR lower(email) = :value", {:value => login.downcase}]).first
    else
      where(conditions).first
    end
  end


  # @return <String> either nil or Users::Relationship#relationship_type (in caps)
  def relationship_type_to(secondary_user)
    rel = user_relationships.find { |r| r.secondary_user_id == secondary_user.id }
    t = rel.try(:relationship_type).to_s.upcase
    if t.blank? && self.child_of?(secondary_user)
      ::Users::Relationship::RelationshipType::CHILD
    else
      t
    end
  end

  # @return <String> either 'Dad', 'Mom' or titleized form of relationship_type_to result
  def informal_relationship_to(secondary_user)
    relationship = relationship_type_to(secondary_user)
    case relationship
      when 'FATHER'
        relationship = 'Dad'
      when 'MOTHER'
        relationship = 'Mom'
      else
        relationship = relationship.titleize
    end
    relationship
  end

  def login
    @login ||= user_name || email
  end

  def parent_of?(child)
    child.parents.include?(self)
  end

  def child_of?(parent)
    parent.children.include?(self)
  end

  def has_follower?(user_or_user_id)
    ::Stores::Following.where(user_id: id, follower_user_id: (
    user_or_user_id.is_a?(User) ? user_or_user_id.id : user_or_user_id)).count > 0
  end

  def male?
    self.gender.to_s.upcase == 'MALE'
  end

  def female?
    self.gender.to_s.upcase == 'FEMALE'
  end

  def kid_gender
    female? ? 'Girl' : 'Boy'
  end

  def possessive_form
    female? ? 'her' : 'his'
  end

  def pronoun_form
    female? ? 'she' : 'he'
  end

  def object_form
    female? ? 'her' : 'him'
  end

    # Personalized name for display.
  def name(options = {})
    s = first_name
    s << ' ' if options[:include_last_name]
    s
  end

  # Alternate form of user's name either the name or user_name
  def display_name
    #name.blank? ? user_name : name
    user_name
  end

  # An ensure-to-exist email. A parent may not enter email for the child, so emails would be directed
  # to the parent's email.
  def contact_email
    self.email.valid_email? ? self.email : self.parents.collect(&:email).first
  end

  ##
  # The chosen image of either uploaded profile picture file or system-provided avatar picture.
  # * +image_version+ optional.  either :url or :thumbnail for the uploaded file.
  def profile_image_url(image_version = :url)
    url = profile_image.try(image_version)
    if profile_image_name.present?
      url = ::User.to_profile_image_url(profile_image_name)
    end
    url
  end

  ##
  # the_other_user <integer or User>
  def is_mutual_friend?(the_other_user)
    the_other_user_id = the_other_user.is_a?(User) ? the_other_user.id : the_other_user.to_i
    following_user_ids = ::Stores::Following.where(user_id: self.id).collect(&:follower_user_id)
    following_user_ids.include?(the_other_user_id) && followings.where(user_id: the_other_user_id).any?
  end

  def score(other_user, favorite_item_model)
    score = 1
    #going to make the calls here instead of calling mutual friend since the is_mutual_friend? method will do the same.
    #need to add the date stuff to the scoring function.
    self_followed_ids = self.followed_users.collect(&:id)
    other_followed_ids = self.followed_users.collect(&:id)
    other_follows_self = self_followed_ids.include? other_user.id
    self_follows_other = other_followed_ids.include? self.id
    if other_follows_self and self_follows_other
      #mutual friends situation
      score = 2000
    elsif self_follows_other or other_follows_self
      #one follows the other
      score = 1000
    end
    time_score = (DateTime.now.to_i - favorite_item_model.created_at.to_i) / 100
    score + time_score
  end

  ##
  # In the same school, within nearby by grades.
  # the_other_user <User>
  def is_within_circle?(the_other_user)
    return false if the_other_user.current_school_id != self.current_school_id
    if self.grade.to_i != 0
      ::Schools::SchoolGroup.grades_around(self.grade).include?( the_other_user.grade )
    else
      true # no grade
    end
  end

  ##
  # Collects the list of siblings within this family whether self is parent or child
  # @return <Array of integers, the user IDs>
  def family_user_ids
    the_parent_id = self.is_a?(Parent) ? self.id : self.parent_id
    user_ids = ::Users::Relationship.where(primary_user_id: the_parent_id, relationship_type: ::Users::Relationship::PARENTS).collect(&:secondary_user_id)
    user_ids << self.id if self.is_a?(Child) && user_ids.blank? # workaround for broken user relationships
    user_ids
  end

  # @return <Array of User>
  def family_users
    User.where(id: family_user_ids).all
  end

  MINIMUM_ITEM_COUNT_BEYOND_NEW = 10

  ##
  # Whether the user has participated enough in the system.
  def new_user?
    trade_count == 0 && [item_count, Item.owned_by(self).count ].max < MINIMUM_ITEM_COUNT_BEYOND_NEW &&
        ::Schools::SchoolGroup.get_schoolmates(self.id).size <= 1
  end

  def json_user_name
    user_name.blank? ? first_name : user_name
  end

  ##
  # Minimized set of attributes.
  # Extra options:
  #   :relationship_to_user <User>: passed onto User attributes to better rename the users;
  #     for example, pass in the child and sender being the father would show name 'Dad'

  def as_json(options = {} )
    result = {id: id, name: name, user_name: json_user_name, type: type.to_s, email: email, first_name: first_name, last_name: last_name,
     parent_id: parent_id, current_school_id: current_school_id.to_i, current_school_name: current_school.try(:name).to_s,
     gender: gender.to_s.titleize, grade: grade.to_s, teacher: teacher.to_s,
     profile_image_url: profile_image_url, item_count: item_count, trade_count: trade_count, number_of_items_for_sale: item_count,
     number_of_past_transactions: trade_count, is_mutual_friend: false,
     account_confirmed: ::Items::ItemInfo::REQUIRES_ACCOUNT_CONFIRMATION_TO_ACTIVATE ?  account_confirmed : true,
     finished_registering: finished_registering, is_parent_email: is_parent_email
    }
    result.stringify_keys
  end

  alias_method :json_attributes, :as_json

  ##
  # @options <Hash> the same options passed to as_json
  def as_more_json(options = {}, other_user_id = nil, real_name = nil)
    result = as_json(options )
    if not other_user_id.nil?
      mutual_friends = is_mutual_friend?(other_user_id)
      if mutual_friends
        if real_name.nil?
          result.merge!({is_mutual_friend: true, real_name: first_name})
        else
          result.merge!({is_mutual_friend: true, real_name: real_name})
        end
      else
        result.merge!({is_mutual_friend: false})
      end
    end
    result.stringify_keys
  end


  ##
  # @param collection <Array of User>
  def self.to_csv(collection)

    col_names = %w|id user_name gender first_name avatar school_id school_name grade parent_first_name parent_last_name parent_email address1 address2 city state zip items_approved items_pending account_confirmed|
    CSV.generate do|csv|
      csv << col_names
      collection.each do|user|
        pimage = user.profile_image_name
        if pimage.present?
          pimage = "http://www.kidstrade.com/assets/avatars/#{pimage}" + (pimage.ends_with?('.png') ? '' : '.png')
        end
        row = [user.id, user.user_name, user.gender, user.first_name, pimage ]
        row << user.current_school_id
        row << user.current_school.try(:name).to_s
        row << ::Schools::SchoolGroup::GRADES_HASH[user.grade].to_s
        row << user.parent.first_name
        row << user.parent.last_name
        row << user.parent.email
        row << user.primary_user_location.try(:address)
        row << user.primary_user_location.try(:address2)
        row << user.primary_user_location.try(:city)
        row << user.primary_user_location.try(:state)
        row << ::Geocode::ZipCode.standardize_zip_code( user.primary_user_location.try(:zip).to_s )
        row << Item.open_items.where(user_id: user.id).count
        row << Item.pending.where(user_id: user.id).count
        row << user.parent.account_confirmed?
        csv << row # whole row
      end
    end
  end

  # This is dependent on the current_school_id / current_school attribute.
  def current_school_group
    return nil if current_school_id.nil? || current_school_id.to_i.zero?
    @school_group ||= Schools::SchoolGroup.where(school_id: current_school_id, user_id: id).first
  end

  #############################
  # User management methods

  ##
  # Override of Devise to skip current_password requirement
  def update_with_password(params={})
    if params[:password].blank?
      params.delete(:password)
      params.delete(:password_confirmation) if params[:password_confirmation].blank?
    end
    update_attributes(params)
  end

  # @return <Integer> recent item_count
  def recalculate_item_count!
    items = Item.owned_by(self)
    self.item_count = items.active.count
    self.item_total = items.count
    self.open_item_total = items.open_items.count
    self.save
    self.item_count
  end

  def self.recalculate_item_count_of!(user_id)
    cnt = ::Item.where(user_id: user_id).active.count
    if user = User.find_by_id(user_id)
      user.update_attribute(:item_count, cnt)
    end
    cnt
  end

  def recalculate_trade_count!
    self.trade_count = fetch_trade_count
    self.save
    self.trade_count
  end

  def fetch_trade_count
    ::Trading::Trade.for_user(self.id).accepted.count
  end

  def check_business_card_parent
    if self.is_a?(Child) and not self.business_card_note_sent and ::Item.where(user_id: self.id).count >= TradeConstants::ITEMS_MIN_THRESHOLD
      parent_prompts = ::Users::Notifications::BusinessCardPromptParent.where(recipient_user_id: self.parent_id, uri:"/business_cards/user/#{self.id}").order('id asc')
      child_prompts = ::Users::Notifications::BusinessCardPromptKid.where(recipient_user_id: self.id).order('id asc')
      if parent_prompts.empty?
        ::Users::Notifications::BusinessCardPromptParent.create(recipient_user_id: self.parent_id, sender_user_id: Admin.cubbyshop_admin.id, uri: "/business_cards/user/#{self.id}")
      elsif parent_prompts.size > 1
        ::Users::Notifications::BusinessCardPromptParent.delete_all(id: parent_prompts[0, parent_prompts.size - 1].collect(&:id) )
      end

      if child_prompts.empty?
        ::Users::Notifications::BusinessCardPromptKid.create(sender_user_id: Admin.cubbyshop_admin.id, recipient_user_id: self.id, uri: '/business_cards/')
        self.business_card_note_sent = true
        self.save
        return true
      elsif child_prompts.size > 1
        ::Users::Notifications::BusinessCardPromptKid.delete_all(id: child_prompts[0, child_prompts.size - 1].collect(&:id) )
        return true
      end
    end
    return false
  end

  ##
  # This is destruction of user's related models including entry in users table.
  # If user is parent, would wipe out children also.
  # @param user_id <User or integer ID of user>
  # @return <boolean> whether user is actually deleted.
  def self.wipe_out_user(user_id)
    user = user_id.is_a?(::User) ? user_id : User.find_by_id(user_id)
    return false if user.nil?
    ::Users::Notification.where('recipient_user_id = ? OR sender_user_id = ?', user_id, user_id).delete_all
    ::Users::Relationship.where(secondary_user_id: user_id).delete_all
    Item.where(user_id: user_id).all.each do|item|
      item.item_photos.each(&:destroy)
      item.destroy
    end
    ::Users::FriendRequest.where('recipient_user_id = ? OR requester_user_id = ?', user_id, user_id).delete_all
    ::Users::Boundary.where(user_id: user_id).delete_all
    ::ItemComment.where('recipient_user_id = ? OR buyer_id = ?', user_id, user_id).delete_all
    ::Trading::BuyRequest.where('buyer_id = ? OR seller_id = ?', user_id, user_id).delete_all
    ::Trading::Trade.where('buyer_id = ? OR seller_id = ?', user_id, user_id).delete_all
    ::Trading::TradeComment.where('user_id = ?', user_id).delete_all
    ::Trading::TradeItem.where('seller_id = ?', user_id).delete_all
    ::Stores::Following.where('user_id = ? OR follower_user_id = ?', user_id, user_id).delete_all
    ::Users::UserNotificationToken.where(user_id: user_id).delete_all

    if user.is_a?(::Parent)
      user.children.each {|child| wipe_out_user(child) }
    end

    ::User.delete(user_id)
    true
  end

  def self.recalulate_trade_count_of!(user_id)
    cnt = 0
    if user = User.find_by_id(user_id)
      user.recalculate_trade_count!
      cnt = user.trade_count
    end
    cnt
  end

  # More limited set of attributes than that of mass-assignment for allowing change during existing record update.
  # These should also be in the model's mass-assignment whitelist (attr_accessible)
  ALLOWED_ATTRIBUTES_FOR_UPDATE = [:encrypted_password, :password, :password_confirmation, :current_password,
                                   :email, :user_name, :first_name, :last_name, :interests, :birthdate,
                                   :gender, :current_school_id, :teacher, :grade, :profile_image_name]

  def self.sanitize_attributes(attributes = {})
    clean_attr = {}
    return clean_attr if attributes.nil? || attributes.empty?
    attributes.each_pair { |k, v| clean_attr[k.to_sym] = v if ALLOWED_ATTRIBUTES_FOR_UPDATE.include?(k.to_sym) }
    if attributes[:password].blank? && attributes[:password_confirmation].blank?
      clean_attr.delete(:password)
      clean_attr.delete(:password_confirmation)
    end
    clean_attr
  end

  ##
  # This helps convert User.profile_image_name, which may be short form without @2x and extension (.png)
  def self.to_full_profile_image_name(profile_image_name)
    full_image_name = profile_image_name
    if profile_image_name.match(/\.(jpg|jpeg|png|gif)$/i).nil?
      if profile_image_name.match(/(@2x)$/i ).nil?
        profile_image_name << '@2x'
      end
      full_image_name << '.png'
    end
    full_image_name
  end

  def self.to_profile_image_url(profile_image_name)
    '/assets/avatars/' + to_full_profile_image_name(profile_image_name)
  end


  protected

  def fix_defaults
    self.type ||= 'Parent' if type.blank?
    if self.type == 'Parent' || self.type == 'Admin'
      self.parent_id = 0
      self.finished_registering = true
    end
  end

  def create_default_boundary
    if self.is_a?(Child)
      bound = []
      bound << ::Users::ChildCircleOption.new(user_id: self.id, content_keyword: 'ONE_GRADE_AROUND')
      self.boundaries = bound
      self.save
    end
  end

  def normalize_attributes
    self.first_name = self.first_name.to_s.titleize
    self.last_name = self.last_name.to_s.titleize
    self.email = self.email.to_s.downcase
    self.user_name = self.user_name.to_s.downcase
    if self.gender.to_s.downcase == 'boy'
      self.gender = 'Male'
    elsif self.gender.to_s.downcase == 'girl'
      self.gender = 'Female'
    end
    self.grade = nil if self.grade && !Schools::SchoolGroup::GRADES_HASH.keys.include?(self.grade)
    self.account_confirmed = true if AUTO_CONFIRM_ACCOUNT && self.is_a?(::Parent)
  end

  # The followup to the changes just made to user, for example, an assignment or change to school will have to change
  # the Item#school_id also.
  def apply_related_changes!
    if current_school_id_changed?
      puts " --> User #{user_name} changed school"
      Thread.new {
        Item.where(user_id: id).each { |item| item.index }
        Item.connection.close
      }
    end
  end

end
