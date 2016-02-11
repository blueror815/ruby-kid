class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :verify_auth_user
  before_filter :load_account_data

  respond_to :html, :json

  protected

  def verify_auth_user
    if request.format == 'application/json' && !Rails.env.test?
      doorkeeper_authorize!
    else
      logger.info "=========== request #{request.original_url} w/ controller #{params[:controller]}, action #{params[:action]}"
      if auth_user.nil? && (params[:controller] != 'sessions')
        logger.info "--> HOME"
      else
        set_referer_as_redirect_back
        authenticate_user!
      end
    end
  end

  public

  # Auto set the current :get method page as return page under current controller scope.
  # For example, within the process of displaying edit users from /users/edit and then post update action,
  # the simple redirect_back_to_last_view call would automatically uses last view page under scope of :users.
  # For :items scope, there would be its own last view page, such as /items/1 after posting question to seller.

  def doorkeeper_unauthorized_render_options
    error = {
        success: false,
        errors: [
            {
                type: :unauthorized,
                message: "Not authorized"
            }
        ]
    }
    {:json => error}
  end

  def auth_user
    unless @current_user
      @current_user = User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    end
    @current_user || current_user
  end

  def redirect_back(*page_params)
    if session[:original_uri].blank?
      redirect_to(*page_params)
    else
      redirect_to(session[:original_uri])
    end
  end

  def last_page(extra_param = '')
    s = request.referer || '/'
    if extra_param.present?
      s << ( s.index('?') ? '&' : '?' ) + extra_param
    end
    s
  end

  def set_this_as_redirect_back
    session[:original_uri] = request.url
  end

  def set_referer_as_redirect_back
    session[:original_uri] = request.referer
  end

  def clear_redirect_back
    session[:original_uri] = nil
  end

  protected

  def load_account_data
    @cart ||= ::Carts::Cart.new(auth_user ? auth_user : cookies)

    return if request.format == 'application/json'

    # This disallows guests for now
    if auth_user.nil?
      if !['sessions', 'users', 'users/admin'].include?(params[:controller]) && request.path.match(/^\/admin/).nil?
        logger.info "  .. load_account_data -> login / params #{params}"
        session[:after_sign_in_path] = request.original_url
        redirect_to(new_user_session_path) && return
      end
    else
      clear_redirect_back if params[:returning] # clear away return page when this request is from return page
      if auth_user.is_a?(Parent)
        @notifications_count =  ::Users::Notification.sent_to(auth_user.id).parent_required.in_wait.count
      else
        @notifications_count = ::Users::Notification.sent_to(auth_user.id).in_wait.count
      end
    end
  end

  # Other than auth_user <User> attributes, these provide a summary of status attributes like
  # primary user location, children count, etc.  This is intended for use to help generate JSON response
  def current_user_status_extra_params
    extra_params = {authenticity_token: form_authenticity_token}
    return extra_params if auth_user.nil?

    if auth_user.is_a?(Parent)
      extra_params[:user_children_count] = auth_user.children.count
    end
    if auth_user.primary_user_location_id
      extra_params[:primary_user_location_id] = auth_user.primary_user_location_id
      extra_params.merge!(auth_user.primary_user_location.as_json) if auth_user.primary_user_location
    end
    waiting_count = @notifications_count || ::Users::Notification.sent_to(auth_user.id).in_wait.count
    if waiting_count < 1 && auth_user.is_a?(Parent)
      waiting_count = ::Item.pending.where(user_id: auth_user.children.collect(&:id) ).group_by(&:user_id).size
    end
    extra_params[:notifications_count] = waiting_count
    extra_params
  end

  ##
  # Checks validity of the model and creates a join error message in flash.

  def set_flash_messages_from_errors(model, prepending_sentence = nil, appending_sentence = nil)
    if model && model.errors.count > 0
      full_msg = model.errors.full_messages.join('. ')
      full_msg = prepending_sentence + ' ' + full_msg if prepending_sentence.present?
      full_msg << ' ' + appending_sentence if appending_sentence.present?
      flash[:error] = full_msg
    end
  end

  ##
  # Common response with error for different formats:
  #   html - redirect to html_redirect_path
  #   json - render with hash.  If empty, would just be { success: false, error: flash[:error] }
  def respond_with_error(html_redirect_path, json_hash = {})
    respond_to do|format|
      format.html { redirect_to(html_redirect_path) }
      format.json { json_hash = { success: false, error: flash[:error] } if json_hash.empty?; render json: json_hash }
    end
  end

  protected

  def local_request?
    false
  end

  # Creates a hash that contains errors
  # @return <success: <bool>, errors: [<string>] or [ {error_code: <string>, message: <string> } ]
  def make_json_status_hash(success_or_not, error_code = nil)
    h = { success: success_or_not }
    errors = []
    if flash[:error].present?
      error_code = error_code || flash[:error_code]
      if !error_code.nil?
        errors << {error_code: error_code.downcase, description: flash[:error]}
      else
        errors << flash[:error]
      end
    end
    h[:errors] = errors
    h
  end

  ##
  # If user is specified, and the page should only be accessible by the parent or his child, check is needed.
  # Nothing matters if user_id is not set
  # Filter intended for the /users/(:id or :user_id) requests.
  # user_id <Integer, ID of User>
  def verify_parent_or_child!(user_id)
    if user_id.to_i > 0
      @user = User.find_by_id user_id
      flash[:error] = t('devise.registrations.user_not_found') if @user.nil?
    end
    if @user && (@user.id != auth_user.id && !@user.child_of?(auth_user))
      flash[:error] = t('devise.registrations.no_permission')
    end
    logger.debug "| flash error: #{flash[:error]} | user #{@user}"
    if flash[:error].present? && user_id.to_i > 0
      respond_to do |format|
        format.json { render json: {success: false, error: flash[:error]} }
        format.html { redirect_to(new_user_registration_path) }
      end
    end
  end

  def verify_admin!
    if auth_user.nil? || !auth_user.is_a?(Admin)
      logger.info " verify_admin! on #{auth_user} --> redirecting "
      redirect_to '/403'
    end
  end

end
