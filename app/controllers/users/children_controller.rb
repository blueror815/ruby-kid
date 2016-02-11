class Users::ChildrenController < DeviseController

  include ::Devise::Controllers::SignInOut
  include ::Devise::Controllers::Helpers
  include DeviseExtension
  helper DeviseHelper
  helper ::Users::UsersHelper
  include ::Trading::TradesHelper

  skip_before_filter :require_no_authentication, only: [:new, :create_student] # Devise's
  skip_before_filter :verify_auth_user, only: [:new, :create_student] # ApplicationController

  before_filter :verify_parent!, except: [:create_student]
  before_filter :verify_current_child!, :only => [:edit, :update, :login, :school, :update_school]
  before_filter :load_schools_data, only: [:edit, :new, :update]

  before_filter :doorkeeper_authorize!, except: [:new, :create_student]


  respond_to :html, :json

  def auth_user
    user = User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    user || current_user
  end

  def new
    @child ||= Child.new
    render_as_edit_child
  end

  def edit
    render_as_edit_child
  end

  def index
    @children = auth_user ? auth_user.children : []
    #logger.info "  auth_user: #{auth_user}\n  children: #{@children}"
    respond_to do|format|
      children_json = @children.collect do|child|
        h = child.as_json
        h[:relationship_type] = auth_user.relationship_type_to(child)
        h
      end
      format.json { render json: children_json }
    end
  end

  def create
    @child = Child.new( params[:user] )
    @child.copy_parent_info(auth_user)
    logger.debug "  auth_user #{auth_user.try(:id)} #{auth_user} and \n  child #{@child.attributes}"
    logger.debug "    child valid? #{@child.valid?} w/ errors #{@child.errors.messages}"

    if @child.save && auth_user.add_child!(@child, params[:relationship_type] )
      flash[:notice] = "Successfully added the child."

      # Extra params for SchoolGroup
      @child.update_school_group!(params[:user])

      # if (@child.gender == "Male")
      #   @my_user_subject = "He"
      # else
      #   @my_user_subject = "She"
      # end

      # if(@child.grade != nil)
      #   @min_grade = @child.grade - 1
      #   @max_grade = @child.grade + 1
      # else
      #   @min_grade = 0
      #   @max_grade = 0
      # end

      # @my_registered_users = User.where("current_school_id = :school_id AND grade >= :min_grade AND grade <= :max_grade", { school_id: @child.current_school_id, min_grade: @min_grade, max_grade: @max_grade } )

      # @my_registered_users.each do |my_registered_user|
      #   puts "----registered use for new user notification-----W/#{my_registered_user}"
      #   @my_notification_text = "Do you know #{@child.user_name}?\n#{@my_user_subject} just joined!"
        
      #   @note_count = ::Users::Notification.reject_notes(::Users::Notification.sent_to(my_registered_user.id).not_deleted.includes(:sender)).count
      #   puts"<-----------notificaton count for new user--------->#{@note_count}"
      #   @extra_params = { badge: @note_count, custom_data:{notification_count: @note_count, trade_id: 119, type: 'welcome_kid'} }
      #   ::Users::UserNotificationToken.send_push_notifications_to(my_registered_user.id, @my_notification_text, @extra_params)
      # end
      puts "--------successfully added--------W/#{@child.id}"
      
      ::UserJoinedMessageWorker.perform_async(@child.id)

      respond_to do|format|
        format.json { render json:{success:true, user: @child.json_attributes } }
        format.html { redirect_to( path_for_next_required_step(@child) || profile_return_path ) }
      end
    else
      set_flash_messages_from_errors(@child, "#{'Error'.pluralize(@child.errors.count)} creating the child: ")
      respond_to do|format|
        format.json { render json:{ success:false, errors: @child.errors.messages } }
        format.html { render_as_edit_child }
      end
    end
  end

  ##
  # Child registering without parent's.
  # Although optional, the parameter user[grade] distinguishes whether child needs parental guidance.
  # Required parameters:
  #   user: { first_name, user_name, email, password  }
  # Optional paramesters
  #   user: { current_school_id, grade, teacher }
  # After registration, would sign child in automatically.
  def create_student
    @child = Child.new( params[:user] )
    @child.copy_parent_info(auth_user)
    params[:initial_reg] = true
    logger.debug "| auth #{auth_user.try(:id)}, child valid? #{@child.valid?} w/ errors #{@child.errors.messages}"

    if @child.save && (auth_user.nil? || auth_user.add_child!(@child, params[:relationship_type] ) )

      # Extra params for SchoolGroup
      @child.update_school_group!(params[:user] )

      set_flash_message(:notice, :signed_in) if is_flashing_format?
      sign_in(:user, @child)

      respond_to do|format|
        format.json { render json:{success:true, user: @child.json_attributes } }
      end
    else
      set_flash_messages_from_errors(@child, "#{'Error'.pluralize(@child.errors.count)} creating the child: ")
      respond_to do|format|
        format.json { render json:{ success:false, errors: @child.errors.messages } }
        format.html { render_as_edit_child }
      end
    end
  end

  # This performs the update functions just as the logged-in user does to himself.
  # Therefore, this follows the inner steps of update Devise so be able to use same info process.authenticity_token

  def update
    user_params = params[:user]
    @child.attributes = User.sanitize_attributes(user_params )
    @child.valid?
    logger.info "child attr: #{user_params}"
    logger.info "  Child errors (#{@child.errors.count}): #{@child.errors.full_messages}"

    # Either simple User attributes update or update with password change too.
    if @child.valid? && (@child.password.present? ? @child.update_with_password(user_params ) : @child.save )
      flash[:notice] = "Updated profile of #{@child.first_name} successfully."

      # Extra params for SchoolGroup
      logger.info "  relationship_type param? #{params[:relationship_type]}"
      auth_user.save_user_relationship!(@child.id, params[:relationship_type] ) if params[:relationship_type].present?
      @child.update_school_group!(params[:user] || params )

      respond_to do|format|
        format.json { render json:{success: true, user: @child.attributes } }
        format.html { redirect_to( path_for_next_required_step(@child) || after_update_path_for(@child) ) }
      end
    else
      logger.info "errors: #{@child.errors.full_messages.inspect}\n--------------------"
      set_flash_messages_from_errors(@child, "#{'Error'.pluralize(@child.errors.count)} updating the child: ")
      respond_to do|format|
        format.json { render json:{ success:false, errors: @child.errors.messages } }
        format.html { render_as_edit_child }
      end
    end

  end

  def dashboard_parent
    child = User.find(params[:child_id])
    if not child.nil? and auth_user.parent_of?(child)
      trades = ::Trading::Trade.for_user(child).not_deleted.includes(:trade_items)
      items = fetch_trading_items(trades, child, false, true)
      other_items = Item.owned_by(child).pending_then_open
      if items.nil?
        if other_items.nil?
          items = []
        else
          items = other_items.sort_by {|item| item.updated_at}
        end
      else
        if other_items.nil?
          items = items.sort_by {|item| item.updated_at}
        else
          items.sort_by! {|item| item.updated_at}
          other_items.sort_by! {|item| item.updated_at}
          items = items + other_items
          items = items.uniq(&:id)
        end
      end
      #they're getting lost somewhere in here
      result = items.map {|i| i.as_json()}
    end #this is if child is nill and/or auth_user is not a parent of the child. return nothing
    if result.nil?
      respond_to do |format|
        format.json {
          render status: 403,
          json: {:success => "failure"}
        }
      end
    else
      respond_to do |format|
        format.json {
            render status: 200,
            json: result
        }
      end
    end
  end

  def school
    @page_title = 'Pick School'
    @schools = ::Schools::School.search_with_location(auth_user.primary_user_location ).limit(100)
    logger.info "| found #{@schools.size} for #{auth_user.primary_user_location}"
  end

  def update_school
    @school = ::Schools::School.find_by_id(params[:school_id])
    if @school && @child
      @child.update_attributes(current_school_id: @school.id)
    end
    respond_to do|format|
      format.html { redirect_to notifications_path }
      format.html { render(json:{ success: true, school: @school.try(:to_json) } ) }
    end

  end

  ##
  # As a parent, login the his/her child's account as convenience.

  def login
    sign_in(:user, @child)
    respond_to do|format|
      format.json { render json: @child.json_attributes.merge( current_user_status_extra_params ) }
      format.html { redirect_to after_sign_in_path_for(@child) }
    end
  end


  protected

  # Current user logged in is actually the parent
  def require_no_authentication
    unless auth_user.is_a?(Parent)
      super
    end
  end

  def render_as_edit_child
    render('users/children/edit_child')
  end

  # @return nil if nothing else required
  def path_for_next_required_step(user)
    if user.user_locations.count.zero? && (user.is_a?(Parent) ? true : user.parents.sum{|parent| parent.user_locations.count }.zero? )
      flash[:notice] = "#{flash[:notice]}  And please enter your address too."
      new_user_location_path
    else
      nil
    end
  end


  def profile_return_path
    # {controller: '/users', action: 'edit', tab: 'children'}
    edit_user_registration_path(tab: 'children')
  end

  def verify_parent!
    unless auth_user.try(:is_a?, Parent)
      flash[:error] = t('devise.registrations.must_be_a_parent')
      # redirect_back('/users/edit') && return
      edit_user_registration_path && return
    end
  end

  def verify_current_child!
    flash.clear # somehow left over flash would ruin
    @user = @child = User.find_by_id(params[:id])
    if @child.nil?
      flash[:error] = t('devise.registrations.user_not_found')
    else
      if auth_user.id != @child.id && !auth_user.parent_of?(@child)
        flash[:error] = t('devise.registrations.no_permission')
      end
      params[:relationship_type] ||= auth_user.relationship_type_to(@child)

    end
    logger.info "| flash error #{flash[:error] }"
    if @child && !@child.new_record?

    end
    if flash[:error].present?
      respond_to do|format|
        format.json { render json: { success: false, error: flash[:error] } }
        format.html { redirect_back(profile_return_path) }
      end
    end
  end

  def load_schools_data
    if auth_user.is_a?(Parent)
      current_location = @child.try(:primary_user_location) || auth_user.primary_user_location
      @schools = ::Schools::School.search_with_location(current_location, params)
    end

  end

  def doorkeeper_authorize!
    if auth_user.nil? && request.format == 'application/json'
      super
    else
      verify_authenticity_token
    end
  end

end
