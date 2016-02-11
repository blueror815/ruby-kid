module Users
  class AdminController < ApplicationController

    helper ::Users::UsersHelper

    before_filter :verify_admin!
    before_filter :find_current_user, only: [:update_user, :delete_user]

    REAL_USERS_START_TIME = DateTime.new(2015,10,9,15,0,0, '-05:00')

    ##
    # Admin for show & exporting the list of users since launch.
    def users
      @page_title = 'Registered Users'
      begin
        @start_time = params[:start_time].present? ? DateTime.parse(params[:start_time]) : REAL_USERS_START_TIME
      rescue
        @start_time = REAL_USERS_START_TIME
      end
      test_only = params[:test_only].to_i == 1

      respond_to do|format|
        format.html do
          User.per_page = params[:limit] || 20
          @users = Child.where('created_at > ? and is_test_user = ?', @start_time, test_only ).order('id asc').paginate(page: params[:page] )
          render 'admin/users'
        end
        format.csv do
          @users = Child.where('created_at > ? and is_test_user = ?', @start_time, test_only ).order('id asc').to_a
          send_data ::User.to_csv(@users)
        end
      end
    end

    def update_user
      @user.attributes = params[:user]
      if @user.save
        if @user.is_a?(::Child) && @user.parent
          @user.parent.attributes = @user.attributes.select{|k,v| %w|is_test_user|.include?(k)  }
          @user.parent.save
        end
      else
        set_flash_messages_from_errors(@user)
      end
      respond_to do|format|
        format.js { render 'admin/update_user' }
        format.html { redirect_to last_page("t=#{Time.now.to_i}") }
      end
    end

    def delete_user
      ::User.wipe_out_user(@user.id)
      respond_to do|format|
        format.js { render 'admin/delete_user' }
        format.html { redirect_to last_page("t=#{Time.now.to_i}") }
      end
    end

    ##
    # Admin for listing schools
    def schools
      ::Schools::School.per_page = params[:limit] || 50
      @schools = ::Schools::School.order('id asc')
      if params[:filter].to_s != 'all'
        @schools = @schools.not_validated_by_admin
      end
      @schools = @schools.paginate(page: params[:page] )

      render layout: 'minimal', template: 'admin/schools'
    end

    NOTIFICATIONS_MODEL_PATH = "#{Rails.root}/app/models/users/notifications/"

    ##
    # Management of notification types in terms of wordings
    def notifications
      @page_title = 'Notifications Manager'
      Dir.foreach(NOTIFICATIONS_MODEL_PATH){|model_path| require NOTIFICATIONS_MODEL_PATH + model_path if model_path.index('.') != 0 }
      @notification_classes = ::Users::Notification.subclasses
    end

    ##
    # Splash page, gateway before launch.
    def show
      template = 'users/admin'
      render(layout: 'minimal', template: template)
    end

    ##
    # Admin Dashboard leading to different admins.
    def index
      render template:'admin/index', layout:'minimal'
    end

    protected

    def find_current_user
      @user = User.find_by_id(params[:id])
      if @user.nil?
        flash[:error] = 'The requested user cannot be found'
        redirect_to admin_path
      end
    end

  end

end
