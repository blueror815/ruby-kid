class Child < User

  PARENT_GUIDANCE_GRADE_THRESHOLD = 5

  validate :validate_child_status
  validate :validate_with_siblings

  after_update :user_checks!
  after_create :create_messages!


  def requires_parental_guidance?
    grade.to_i < PARENT_GUIDANCE_GRADE_THRESHOLD
  end

  ##
  # Whether any child action would need to contact the parent.  This depends on requires_parental_guidance?.
  def should_contact_parent?
    parent && requires_parental_guidance?
  end

  def parent
    @parent ||= (self.parent_id.to_i == 0) ? nil : ( User.find_by_id(self.parent_id) || self.parents.first )
  end

  # This helper method checks if any parent, parent is account_confirmed, else self account_confirmed
  def account_confirmed?
    parent ? parent.account_confirmed : self.account_confirmed
  end

  ##
  # If child self doesn't have user location, would be primary_user_location, which is likely be parent's.
  def user_locations
    unless @user_locations
      @user_locations = super
      @user_locations = [primary_user_location].compact if @user_locations.blank?
    end
    @user_locations
  end

  ##
  # If not set, copy over parent's primary_user_location_id, email
  def copy_parent_info(_parent = nil)
    _parent ||= @parent # could've already been set manually
    if _parent && _parent.is_a?(Parent)
      self.primary_user_location_id ||= _parent.primary_user_location_id
      self.parent_id = _parent.id
      self.is_parent_email = true
      @parent ||= _parent

    else # draft user
      self.parent_id ||= 0
      self.finished_registering = false
      if requires_parental_guidance?
        self.is_parent_email = true
      else
        self.is_parent_email = false
      end
    end
  end

  # Override of the scope, so if somehow primary_user_location_id not yet, can still refer to parent's location
  def primary_user_or_parent_location
    if (primary_user_location_id.nil?)
      copy_parent_info
    end
    self.primary_user_location
  end

  ##
  # Minimized version of the call to optimize query calls
  def relationship_type_to(secondary_user)
    if secondary_user.is_a?(Parent)
      super(secondary_user)
    else
      secondary_user.try(:id) == self.id ? ::Users::Relationship::RelationshipType::SELF : nil
    end
  end

  # Either creates or updates attributes of Schools::SchoolGroup
  # params <Hash>
  #   :grade <integer> the value that confirms into SchoolGroup::GRADES_HASH.keys
  #   :teacher <String>
  def update_school_group!(params)
    puts "current school #{self.current_school}\nparams #{params}"
    @school_group = current_school_group
    if self.current_school
      @school_group ||= ::Schools::SchoolGroup.new(user_id: self.id, school_id: self.current_school_id)
      puts "  school group: new? #{@school_group.new_record?}  user_id #{@school_group.user_id}, school_id #{@school_group.school_id}"
      @school_group.attributes = {teacher: params[:teacher], grade: (params[:grade] ? params[:grade].to_i : nil)}

      puts "    user_id #{@school_group.user_id}, school_id #{@school_group.school_id}, grade #{@school_group.grade}, teacher #{@school_group.teacher}e"
      @school_group.save
    elsif self.current_school_id_changed? && self.current_school_id.to_i == 0
      ::Schools::SchoolGroup.delete_all(user_id: self.id) > 0
    else
      false
    end
  end

  # after_create
  def create_messages!
    if ::Users::Notifications::WelcomeKid.where(recipient_user_id: self.id).empty?
      ::Users::Notifications::WelcomeKid.create(sender_user_id: Admin.cubbyshop_admin.id, recipient_user_id: self.id)
    end
    if self.parent_id.to_i > 0
      ::Jobs::ChildLoginReminder.new(self.id).enqueue!
    end
  end

  # after_update
  def user_checks!
    return if self.parent_id.to_i == 0
    if last_sign_in_at_was.nil? && last_sign_in_at
      ::Jobs::ChildPostingReminder.new(self.id).enqueue!
    elsif profile_image_name_was.blank? && profile_image_name.present?
      ::Jobs::ChildNeverPostedCheck.new(self.id).enqueue!
    end
    if ::Items::ItemInfo::REQUIRES_PARENT_APPROVAL == false && finished_registering_changed? && finished_registering
      update_count = ::Item.owned_by(self).pending_approval.update_all(status: ::Item::Status::OPEN)
      logger.info ">> Activated pending items of child #{user_name}: #{update_count}"
    end
  end

  protected

  ##
  #
  def validate_child_status
    if parent_id.to_i == 0
      self.errors.add(:email, I18n.t('child.registration.email_missing') ) if email.blank?
    end
  end

  def validate_with_siblings
    return if self.parent_id.nil? || self.parent.nil?

    same_first_name = self.parent.children.find{|sibling| sibling.id != self.id && sibling.first_name.downcase.strip == self.first_name.downcase.strip }
    if same_first_name
      self.errors.add(:first_name, I18n.t("child.registration.duplicate_first_name") )
    end
  end

end
