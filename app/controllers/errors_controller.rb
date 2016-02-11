class ErrorsController < ApplicationController

  skip_before_filter :verify_auth_user
  skip_before_filter :load_account_data

  def show
    @exception = env["action_dispatch.exception"]
    logger.warn "** #{@exception.message}\n" << @exception.backtrace.join("\n\t") if @exception
    respond_to do |format|
      format.html { render action: request.path[1..-1] }
      format.json { render json: {status: request.path[1..-1], error: @exception.try(:message)} }
    end
  end

  def log_into_app
    params[:hide_footer_icons] = true

    respond_to do|format|
      format.html
    end
  end
end