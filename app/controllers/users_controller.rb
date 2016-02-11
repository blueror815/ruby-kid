class UsersController < Devise::RegistrationsController

  include ::Devise::Controllers::SignInOut
  include DeviseExtension
  helper DeviseHelper
  include ::Users::UsersHelper
  include ::Trading::TradesHelper

  skip_before_filter :require_no_authentication, only: [:new, :create]
  before_filter :load_schools_data, only: [:edit, :new, :update]
  before_filter :load_child, only: [:new, :create]
  before_filter :verify_editor!, only: [:show, :show_current_user, :edit, :update, :dashboard, :friends]

  skip_before_filter :verify_auth_user, only: [ :create ]

  respond_to :html, :json

  def auth_user
    user = User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    user || current_user
  end

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

  def new

  end

  def edit

  end

  def followings
    #auth user is the "follower_user_id"
    if auth_user.followings.empty?
      result = []
    else
      result = auth_user.followings.collect(&:user_id)
    end

    respond_to do |format|
      format.json {
        render json: {
          followings: result
        }
      }
    end
  end

  # Override of Devise::RegistrationsController#create.
  # Pretty much simulate super's run to build the user model first and check validity with added JSON response.
  # If JSON response would contain attributes that includes selected final attributes of user if successful or
  # 'errors' parameter with list of messages if failure.
  def create
    build_resource(sign_up_params)
    if resource.save

      save_image_attribute!(sign_up_params[:profile_image] || sign_up_params[:profile_image_name], params[:remove_profile_image])

      child = (auth_user && auth_user.is_a?(Child)) ? auth_user : (params[:child_id] ? User.find_by_id(params[:child_id]) : nil)
      if child.is_a?(Child)
        connect_parent_and_child!(resource, child)
      end
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_up(resource_name, resource)

      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
      end
      respond_to do |format|
        format.json { render :json => {:success => true, :user => resource.json_attributes} }
        format.html { redirect_to(user_locations_path(initial_reg: params[:initial_reg], child_id: params[:child_id] ) ) }
      end
    else
      clean_up_passwords resource
      logger.info "  Errors: #{resource.errors.full_messages}"
      respond_to do |format|
        format.json { render :json => {:success => false, :errors => resource.errors.messages} }
        format.html { params[:initial_reg] ? redirect_to(user_locations_url) : redirect_to(edit_user_registration_path) }
      end
    end
  end

  def business_cards

    if params['not_now'].to_s == 'true' # app could be sending string form
      notes = ::Users::Notifications::BusinessCardPromptKid.where(recipient_user_id: auth_user.id)
      if not notes.empty?
        note = notes.last
        note.status = ::Users::Notification::Status::DELETED
        note.save
      end

      logger.info "-> Deliver business_card mail w/ #{params[:url]}"
      ::NotificationMail.create_from_mail(::Admin.cubbyshop_admin.id, auth_user.id, ::UserMailer.business_card(auth_user, params[:url]) )
    end
    respond_to do |format|
      format.json {
        render :json => {
          :success => true
        }
      }
    end
  end


  def update
    @user ||= resource
    if @user.nil?
      @user ||= auth_user
      @user.attributes = params['user'] if params['user'].present?
    end
    if (user_params = params[:user]).present?
      if user_params[:password].present? && user_params[:password] != user_params[:password_confirmation]
        @user.errors.add(:password_confirmation, t('devise.registrations.password_confirmation_mismatch'))
      end
    end
    if (user_location = params[:user_location] ).present?
      Users::UserLocation.set_primary_for_user!(@user, user_location)
    end
    if (user_phone = params[:user_phone] ).present?
      Users::UserPhone.set_primary_for_user!(@user, user_phone)
    end
    if @user.errors.count == 0

      respond_to do |format|
        # super update does not handle JSON call specifically.  These executions are copies of necessary update calls from Devise::RegistrationsController.
        logger.info " -- to update w/ account_params #{account_update_params}"
        format.json {

          if update_resource(@user, account_update_params)

            if auth_user.id == @user.id
              sign_in resource_name, @user, bypass: true
            end
            image_param = user_params.try(:[], :profile_image) || user_params.try(:[], :profile_image_name) || params['user[profile_image]'] || params['user[profile_image_name]']
            save_image_attribute!(image_param, params[:remove_profile_image] ) if image_param || params[:remove_profile_image]

            render :json => {:success => true, :user => @user.json_attributes }
          else
            logger.debug "  __| Could not update w/ error #{@user.errors.messages}"
            clean_up_passwords @user
            render :json => {:success => false, :errors => @user.errors.messages}
          end
        }
        format.html {
          super
          image_param = user_params.try(:[], :profile_image) || user_params.try(:[], :profile_image_name),
          save_image_attribute!(image_param, params[:remove_profile_image]) if image_param || params[:remove_profile_image]

        }
      end

    else

      respond_to do |format|
        format.json { render :json => {:success => false, :errors => resource.errors.messages} }
        format.html { redirect_to(edit_user_registration_path) }
      end

    end
  end

  def me
    user_response = current_user_status_extra_params.merge(
        { success: true, message: "Login successful",
          followed_user_ids: ::Stores::Following.where(follower_user_id: auth_user.id).collect(&:user_id),
          user_phones: auth_user.user_phones.collect(&:number),
          min_first_time_photos: ::Trading::Trade::MIN_FIRST_TIME_PHOTOS
        }
      )
    user_response[:user_locations] = auth_user.user_locations if auth_user.user_locations.present?
    auth_user.json_attributes.merge(user_response)
    user_response[:user] = auth_user
    render json: user_response
  end

  def show_current_user
=begin
    puts "-----------------------"
    puts "auth_user: #{auth_user}"
    puts "form_auth: " + form_authenticity_token
    puts "  vs params auth: " + params[request_forgery_protection_token]
    puts "signed_in? #{signed_in?}"
=end
    if @user.nil? && auth_user.nil?
      render status: 401, json: {success: false}
    else
      render status: 200, json: (@user || auth_user).json_attributes.merge(current_user_status_extra_params.merge({success: true}))
    end

  end

  ##
  #
  def dashboard
    @user ||= auth_user
    @page_title = 'Dashboard'
    if params[:id] && @user
      @page_title = @user.display_name + ' Dashboard'
    end
    if @user.is_a?(Child)
      @items = Item.owned_by(@user).pending_then_open.includes(:user, :item_photos)
      @favorite_counts = ::Items::FavoriteItem.make_favorite_counts_map(@items.collect(&:id))


      set_with_trading_info!(@items, @user, false)

      @items.sort! do|x, y|
        y.owner_sort_priority({:favorite_counts => @favorite_counts}, auth_user.id ) <=> x.owner_sort_priority({:favorite_counts => @favorite_counts}, auth_user.id )
      end

      logger.debug "Child #{@user.display_name} --------------"
      logger.debug "  #{@items.size} items"
      #@items.each do|item|
      #  active_trade_h = item.active_trade_json
      #  logger.debug "| %5d | status %8s | needs_action? %5s | breathing? %5s | %s | %s" %
      #                  [ item.id, item.status, active_trade_h.try(:[], :needs_action), active_trade_h.try(:[], :breathing), active_trade_h.try(:[], :title), active_trade_h.try(:[], :subtitle) ]
      #end

    else
      @items = []
      @favorite_counts = []
    end

    respond_to do|format|
      format.json { render json: {items: @items.collect(&:more_json), favorite_counts: @favorite_counts, total_count: @total_count} }
      format.html { render template: @user.is_a?(Parent) ? 'users/dashboard_for_parent' : 'users/dashboard_for_child' }
    end
  end

  def show
    if @user.nil? && auth_user.nil?
      render status: 401, json: {success: false}
    else
      render status: 200, json: @user
    end
  end

  ##
  # Currently the friends list is simply the other users that the user is following.
  def friends
    @user ||= auth_user
    friends = ::User.search_users_in_circle(@user).results
    following_user_ids = ::Stores::Following.where(user_id: @user.id).collect(&:follower_user_id) # others following user
    followings = ::Stores::Following.where(follower_user_id: @user.id).includes(:user).order('last_traded_at desc, id desc') # user following others, already ordered newest to oldest
    followed_user_ids = Set.new # for excluding the non-followers
    both_side_followers = []
    one_side_followers = []
    bound = :circle
    user_ids_to_exclude = []
    auth_user.boundaries.group_by(&:type).each do|btype, blist|
      case btype
        when 'Users::ChildCircleOption'
          case blist.first.content_keyword
            when 'GRADE_ONLY'
              bound = :grade
            when 'CLASS_ONLY'
              bound = :class
          end
        when 'Users::UserBlock'
          user_ids_to_exclude = user_ids_to_exclude + ::Users::Boundary.extract_content_values_from_list(blist)
      end
    end
    followings.each do|following|
      user = following.user
      is_mutual = following_user_ids.include?(following.user_id) # y is also following user
      user.is_follower = true
      user.is_mutual_friend = is_mutual
      if is_mutual
        both_side_followers << user.as_more_json({}, auth_user.id)
      else
        if bound.eql? :circle and ::Schools::SchoolGroup.grades_around(auth_user.grade).include?(user.grade)
          one_side_followers << user.as_more_json({}, auth_user.id)
        elsif bound.eql? :grade and auth_user.grade.eql?(user.grade)
          one_side_followers << user.as_more_json({}, auth_user.id)
        elsif bound.eql? :class and auth_user.teacher.eql? user.teacher
          one_side_followers << user.as_more_json({}, auth_user.id)
        end
      end
      logger.debug "  | %20s | %1s | %10d" % [user.user_name, is_mutual ? 'B' : 's', following.id]
      followed_user_ids << following.user_id
    end
    non_followers = friends.find_all {|friend| !followed_user_ids.include?(friend.id) }.sort{|x,y| y.id <=> x.id } # newest registered friends
    logger.debug "-------- #{both_side_followers.size} both side, #{one_side_followers.size} one side, #{non_followers.size} non-followers"
    @friends = both_side_followers + one_side_followers + non_followers.as_json
    #if they're blocked, remove them regardless.
    result = @friends.map do |friend|
      if not user_ids_to_exclude.include?(friend['id'])
        friend
      else
        nil
      end
    end
    result = result.compact
    respond_to do|format|
      format.json { render json:{ success: true, users: result} }
      format.html
    end
  end

  protected

  def verify_editor!

    verify_parent_or_child!( params[:id] || params[:user_id] )

  end

  ##
  # Override of default version
  def authenticate_user!(*args)
    if auth_user && !auth_user.is_a?(::Admin)
      verify_editor!
    end
  end

  def load_schools_data
    if params[:tab].to_s.downcase == 'children' && auth_user.is_a?(Parent)
      current_location = auth_user.primary_user_location
      @schools = ::Schools::School.search_with_location(current_location, params)

    end

  end

  def load_child
    @child = User.find_by_id(params[:child_id]) if params[:child_id]
    # Trick to bypass unique email validation during parent creation
    if @child && @child.is_parent_email && @child.email.present? && params[:user].present?
      params[:user][:email] = 'parent-owned-' + @child.email
      params[:initial_reg] = true
    end
  end

  def doorkeeper_authorize!
    if auth_user.nil? && request.format == 'application/json'
      super
    elsif request.format != 'application/json'
      verify_authenticity_token
    end
  end

  ##
  # * +image_param+ <::ActionDispatch::Http::UploadedFile or String>.  Being an image name alone, without subfolder or subpath;
  #     for example "moneky.png" would be stored in
  def save_image_attribute!(image_param, should_remove_profile_image)
    logger.info "  save_image: #{image_param}, should_remove? #{should_remove_profile_image}"
    if image_param.is_a?(::ActionDispatch::Http::UploadedFile) || should_remove_profile_image
      resource.profile_image_name = ''
      if should_remove_profile_image
        resource.try(:remove_profile_image!)
      else
        resource.profile_image = image_param
      end
      resource.save
      logger.debug " after: (#{resource.profile_image.class}) path: #{resource.profile_image.try(:current_path)}"

    elsif image_param.is_a?(String)
      resource.try(:remove_profile_image!)
      resource.profile_image_name = image_param
      resource.save
      logger.info "  __| chosen avatar image #{image_param}"
    end

  end

  def connect_parent_and_child!(parent, child, relationship_type = nil)


    ActiveRecord::Base.transaction do
      relationship = parent.user_relationships.find{|rel| rel.secondary_user_id == child.id }
      relationship ||= ::Users::Relationship.create(primary_user_id: parent.id, secondary_user_id: child.id)
      relationship.relationship_type = relationship_type.present? ? relationship_type : ::Users::Relationship::RelationshipType::GUARDIAN
      relationship.save

      parent.email = child.email

      child.email = nil
      child.parent_id = parent.id
      child.finished_registering = true
      child.save

      parent.save
    end

    sign_out(:user)
  end

end
