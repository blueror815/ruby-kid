class Users::UserNotificationTokensController < ApplicationController

  skip_before_filter :verify_authenticity_token

  #should only be accessed by an API call.
  def create

    token_params ={
      user_id: auth_user.id,
      platform_type: params[:type],
      token: params[:device]
    }

    unless ::Users::UserNotificationToken.where(user_id: auth_user.id, platform_type: params[:type], token: params[:device]).empty?
      respond_to do |format|
        format.json {
          render json: {
            success: true
          }
        }
      end
    else
      @notification_token = ::Users::UserNotificationToken.new(token_params)
      respond_to do |format|
        if @notification_token.save
          format.json {render json: { success: true}}
        else
          format.json {
            render json: {
              error: @notification_token.errors.first.join(' '), success: false,
              status: 400
            }
          }
        end
      end
    end
  end
end
