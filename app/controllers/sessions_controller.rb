class SessionsController < Devise::SessionsController

  before_filter :ensure_params_exist, only: [:create]
  skip_before_filter :verify_auth_user, only: [:video]
  respond_to :json

  ##
  # Overriding version to add JSON type response.

  def create
    resource = warden.authenticate(auth_options)
    return invalid_login_attempt unless resource

    if resource.valid_password?(resource_params[:password])

      set_flash_message(:notice, :signed_in) if is_flashing_format?
      sign_in(resource_name, resource)

      if resource.timezone.blank?
        resource.timezone = browser_timezone
        resource.save
      end

      ::Users::UserTracking.record_user_request!(resource, request, :login, time_zone: browser_timezone )

      if auth_user.is_a?(Parent) && ::Items::ItemInfo::REQUIRES_PARENT_APPROVAL
        auth_user.children.each do|child|
          ::Users::Notifications::IsWaitingForApproval.update_approval_notification!(child, auth_user)
        end
      end

      yield resource if block_given?
      respond_to do |format|
        format.html { redirect_to after_sign_in_path_for(resource) }
        format.json { render json: extra_user_json_hash }
      end
    else
      logger.info "C2) -------- invalid login"
      return invalid_login_attempt
    end
  end

  def video
    respond_to do |format|
      format.json {
        render json: {
          url: ::HomeHelper::HOW_IT_WORKS_VIDEO_URL_FOR_KID_DIRECT
        }
      }
    end
  end

  def destroy

    ::Users::UserTracking.record_user_request!(auth_user, request, :logout)

    respond_to do|format|
      format.json {
        signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
        render json: { success: true, status: signed_out }
      }
      format.html { super }
    end
  end

  def sign_in_as
    @user = User.find_by_id(params[:id])
    if @user && auth_user.parent_of?(@user)
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
      sign_in(:user, @user)

      respond_to do |format|
        format.html { redirect_to after_sign_in_path_for(resource) }
        format.json { render json: extra_user_json_hash }
      end

    else
      if @user.nil?
        flash[:error] = t("devise.registrations.user_not_found")
      elsif not auth_user.parent_of?(@user)
        flash[:error] = t("devise.registrations.no_permission")
      end
      respond_to do|format|
        format.json { render :json => {success: false, message:flash[:error] }, :status => 200 }
        format.html { redirect_to new_user_session_path }
      end
    end
  end

  protected

  def ensure_params_exist
    return unless params[:user].blank?
    render :json => {success: false, message: "Missing login info"}, :status => 422
  end

  def invalid_login_attempt
    warden.custom_failure!
    user_params = params[:user]
    if user_params[:login].blank?
      flash[:error] = "You need to enter your User ID"
    elsif user_params[:password].blank?
      flash[:error] = "You need to enter your Password"
    else
      flash[:error] = "Your User ID and Password do not match our records.";
    end

    respond_to do|format|
      format.json { render :json => {success: false, message:flash[:error] }, :status => 200 }
      format.html { redirect_to new_user_session_path }
    end
  end

  ##
  # Override.
  # Added check for not-set personal address, so can redirect to enter address immediately as requirement.

  def after_sign_in_path_for(resource)
    after_sign_in_path = session[:after_sign_in_path] || session[:original_uri]
    if after_sign_in_path.present?
      logger.info "--- after sign-in return to #{after_sign_in_path} --------/"
      session[:after_sign_in_path] = nil
      session[:original_uri] = nil
      after_sign_in_path
    else

      if auth_user.is_a?(Parent) && (parent_rel = resource.user_relationships.parenthood).present? # minimal DB query
        pending_approvals = ::Item.pending_approval.where(user_id: parent_rel.collect(&:secondary_user_id) ).select('id,user_id,status').group_by(&:user_id)
        if pending_approvals.size == 1 # multiple would need parent to choose from message board
          after_sign_in_path = inventory_approve_item_path(user_id: pending_approvals.keys.first)
        elsif !User::AUTO_CONFIRM_ACCOUNT && !auth_user.account_confirmed
          pending_confirmations = ::Item.pending_account_confirmation.where(user_id: parent_rel.collect(&:secondary_user_id) ).select('id,user_id,status').group_by(&:user_id)
          if pending_confirmations.present?
            after_sign_in_path = account_confirmation_path
          end
        end
      end
      if after_sign_in_path.blank?
        after_sign_in_path = resource.is_a?(Admin) ? admin_path : (resource.is_a?(Parent) ? notifications_path : root_path)
      end
      logger.info "  \\--- changed after_sign_in to #{after_sign_in_path} --------/"
    end

    after_sign_in_path
=begin
      if auth_user.is_a?(Parent) && Users::UserLocation.where(user_id: auth_user.id).count.zero?
      flash[:notice] = "Please enter your address first."
      new_user_location_path
    else
      if ::Users::Notification.sent_to(auth_user.id).in_wait.count  > 0
        notifications_path
      else
        users_dashboard_path
      end
    end
=end
  end

  def extra_user_json_hash
    extra_params = current_user_status_extra_params.merge( { success: true, message: "Login successful",
                                                             followed_user_ids: ::Stores::Following.where(follower_user_id: auth_user.id).collect(&:user_id) } )
    auth_user.json_attributes.merge( extra_params )
  end
end
