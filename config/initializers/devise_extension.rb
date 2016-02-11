module DeviseExtension

  def self.included(base)
    base.send :after_filter, :set_flash_messages, :only => [:create, :update, :edit]
  end

  def set_flash_messages
    if resource && ( !resource.valid? || resource.errors.count > 0 )
      sentence = I18n.t("errors.messages.not_saved",
                        :count => resource.errors.count,
                        :resource => resource.class.model_name.human.downcase)
      set_flash_messages_from_errors(resource, sentence)
    end
  end

  protected


  def after_update_path_for(resource)
    if resource.is_a?(Child) && auth_user.id != resource.id
      # "/users/child/#{resource.id}"
      users_edit_child_path(resource)

    else
      # "/users/edit"
      edit_user_registration_path
    end
  end

  # Override of Devise controller, makes requirement for password and confirmation to update other
  # attributes of account optional.

  def update_resource(resource, params)
    logger.info "-----------------\nAccount params: #{params.inspect}"
    if params[:password].blank?
      resource.update_without_password(User.sanitize_attributes(params))

    else
      logger.info "Updating with password: #{User.sanitize_attributes(params).inspect} "

      # Instead of calling resource.update_with_password, password is not required


      # Tweak to bypass the required :current_password and :encrypted_password by Devise, so password can be updated too.
      resource.password = params[:password]

      result = if resource.valid_password?(params[:password])

                 resource.update_attributes(params)

               else
                 resource..assign_attributes(params)
                 resource.valid?
                 resource.errors.add(:password, params[:password].blank? ? :blank : :invalid)
                 false
               end

      resource.clean_up_passwords
      result
    end
  end

  # This inherited registrations controller does not provide its own version of dictionary of 
  # messages, so the scope is set back to Devise.

  def devise_i18n_options(options)
    options[:scope] = "devise.registrations"
    options
  end
end