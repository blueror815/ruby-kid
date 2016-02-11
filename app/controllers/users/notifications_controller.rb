module Users
  class NotificationsController < ApplicationController

    before_filter :find_current_notification, :check_permission!, except: [:index, :count, :archive, :delete, :send_push_notification]
    before_filter :verify_admin!, only:[:send_push_notification]

    # GET /users/notifications
    # GET /users/notifications.json
    def index
      @page_title = @menu_title = 'Message Board'

      @user = auth_user

      if params[:list_type].to_s == 'archive'
        @notifications = ::Users::Notification.sent_to(@user.id).already_viewed.includes(:sender)
      elsif params[:list_type].to_s == 'waiting'
        @notifications = ::Users::Notification.sent_to(@user.id).in_wait.includes(:sender)
      else
        @notifications = ::Users::Notification.sent_to(@user.id).not_deleted.includes(:sender).order('status DESC, id DESC')
      end
      # Web-only
      @notifications = @notifications.parent_required if auth_user.is_a?(Parent) && request.format == 'text/html'
      @notifications = @notifications.paginate(page: [1, params[:page].to_i].max, per_page: ::Users::Notification.per_page)

      if (order = normalized_order).present?
        @notifications = @notifications.order(order == 'ASC' ? 'id ASC' : 'id DESC')
      end

      #puts request.headers['X-App-Name'].eql? 'kidstrade-ios'

      @sorted_notifications = @notifications.to_a.sort do|x, y|
        x.compares_with(y)
      end
      ::Users::Notification.set_related_models( @sorted_notifications )

      respond_to do |format|
        format.html { render layout:'landing_25' }
        format.json do
          result = reject_notes(@sorted_notifications);
          render json: (result.collect{|n| n.as_json(relationship_to_user: @user) }  )
        end
      end
    end

    def reject_notes(notifications)
      notifications.reject {|note| (note.title.eql? "" or note.tip.eql? 'Trade Details')}
    end


    def count
      @user = auth_user
      result = @user ? reject_notes(::Users::Notification.sent_to(@user.id).not_deleted.includes(:sender)) : []
      respond_to do |format|
        format.json { render json: {'notifications_count' => result.count } }
      end
    end

    # GET /users/notifications/1
    # GET /users/notifications/1.json
    def show
      if @notification.waiting?
        if @notification.should_be_deleted_after_view?
          @notification.update_attribute(:status, ::Users::Notification::Status::DELETED)

        elsif @notification.should_flag_viewed?
          @notification.update_attribute(:status, ::Users::Notification::Status::VIEWED)
        end
        set_referer_as_redirect_back
      end
      respond_to do |format|
        format.html { redirect_to @notification.uri }
        format.json { render json: @notification.as_json(relationship_to_user: auth_user)
         }
      end
    end

    ##
    # Check whether to delete, set viewed or not changed at all.
    # Single or multiple
    # PUT /notifications/archive ?id=1 or with multiple ?ids[]=34&ids[]=50
    # PUT /notifications/archive.json
    def archive

      ids = params[:ids] || []
      if params[:id].present?
        ids << params[:id]
      end

      to_set_viewed = []
      to_set_deleted = []
      ::Users::Notification.sent_to(auth_user.id).where(id: ids).each do |notification|
        if notification.should_be_deleted_after_view?
          to_set_deleted << notification.id
        elsif notification.should_flag_viewed?
          to_set_viewed << notification.id
        end
      end
      #models.map { |m| m.update_attributes(params) }
      #::Users::Notification.where(id: to_set_viewed).update_all(status: ::Users::Notification::Status::VIEWED) if to_set_viewed.present?
      ::Users::Notification.where(id: to_set_viewed).map {|note| note.update_attributes(status: ::Users::Notification::Status::VIEWED)}
      ::Users::Notification.where(id: to_set_deleted).update_all(status: ::Users::Notification::Status::DELETED) if to_set_deleted.present?

      respond_to do |format|
        format.json { render json: {:notifications_count => ::Users::Notification.sent_to(auth_user.id).in_wait.count} }
        format.html { redirect_to notifications_path(notice: 'Notification was successfully updated.') }
      end
    end

    # DELETE /users/notifications/1
    # DELETE /users/notifications/1.json
    def delete
        @notification = Users::Notification.find_by_id(params[:id])
        @notification.set_status_deleted

        respond_to do |format|
            format.html { redirect_to notification_path }
            format.json { head :no_content }
        end
    end

    # PUT|POST /notifications/push with either :user_id or :user_name
    def send_push_notification
      @user = params[:user_id] ? ::User.find_by_id(params[:user_id]) : nil
      @user = ::User.find_by_user_name(params[:user_name].strip) if params[:user_name].present?
      logger.info "-> #{@user}"
      if @user
        flash[:error] = nil
        ::Users::UserNotificationToken.send_push_notifications_to(@user, params[:text] || params[:notification_text] )
      else
        flash[:error] = 'Cannot find the user'
      end

      respond_to do|format|
        format.js
        format.html { redirect_to last_page("t=#{Time.now.to_i}") }
      end
    end

    private

    def find_current_notification
      @notification = Users::Notification.find_by_id(params[:id])
      unless @notification
        flash[:error] = "The requested notification cannot be found."
        redirect_back(notifications_path) && return
      end
    end

    def check_permission!
      if @notification.recipient_user_id != auth_user.id
        flash[:error] = "You do not have permission to access this notification."
        redirect_back(notification_path) && return
      end
    end

    def normalized_order
      return '' if params[:sort].blank?
      params[:sort].split(/\s+/).last.upcase
    end

  end
end
