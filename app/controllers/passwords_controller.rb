class PasswordsController < Devise::PasswordsController
  prepend_before_filter :require_no_authentication
  # Render the #edit only if coming from a reset password email link
  append_before_filter :assert_reset_token_passed, only: :edit

  skip_before_filter :load_account_data
  skip_before_filter :verify_auth_user

  def create
    if params[:email].present? and params[:user_name].present?
      #child asking their parent ot reset.
      child = User.where(user_name: params[:user_name]).first
      parent = User.where(email: params[:email]).first
      if not child.nil? and not parent.nil? and child.child_of?(parent)
        self.resource = child.send_reset_password_instructions
      end
    elsif params[:email].present?
      user = User.where(email: params[:email]).first
      if user.is_a?(Parent)
        self.resource = user.send_reset_password_instructions
      end
    end
    #puts "got here"

    #sending back true regardless of what happens
    respond_to do |format|
      format.json {
        render :json => {
          :success => true
        }
      }
    end
  end

  protected
    def after_resetting_password_path_for(resource)
      root_path
    end

end
