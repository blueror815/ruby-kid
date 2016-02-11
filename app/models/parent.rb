class Parent < User

  DEFAULT_PARENT_PROFILE_IMAGE_URL = '/assets/avatars/mom.png'

  def should_contact_parent?
    false
  end

  def as_more_json(options = {}, other_user_id = nil, real_name = nil)
    h = super(options, other_user_id, real_name )
    if (relative_child = options.delete(:relationship_to_user) ).present?
      if ( rt = self.relationship_type_to(relative_child) ).present?
        relationship_name = I18n.t("relationship.#{rt.downcase}")
        h[:name] = h[:user_name] = relationship_name if relationship_name.present?
      end
    end
    h[:profile_image_url] = DEFAULT_PARENT_PROFILE_IMAGE_URL if h[:profile_image_url].blank?
    h.stringify_keys
  end

  def confirm_account!
    self.account_confirmed = true
    self.save!

    ::Users::Notifications::NeedsAccountConfirm.where(recipient_user_id: self.id).delete_all

    children.each do |child|
      items = Item.owned_by(child).pending_account_confirmation
      items.each do |item|
        item.activate!
      end
      child.recalculate_item_count!
      ::Users::Notifications::ChildVerifyAccount.where(recipient_user_id: child.id).delete_all
      ::Users::Notifications::PromptKidTrade.create(sender_user_id: Admin.cubbyshop_admin.id, recipient_user_id: child.id)
    end
    #let's call the other method for sending a push notification to the kid to tell them to get trading.
    self.save!
  end

  ##
  # Minimized version of the call to optimize query calls
  def relationship_type_to(secondary_user)
    if secondary_user.is_a?(Child)
      super
    else
      nil
    end
  end

  # Create a parent with some attributes of child
  def self.create_draft_parent(child)
    unless parent = child.parent
      attr = child.attributes.select{|k,v| [:email, :password, :password_confirmation, :last_name].include?(k.to_sym) }
      attr[:first_name] = 'Parent'
      attr[:password] = 'password'
      parent = ::Parent.create(attr)
    end
    parent
  end
end
