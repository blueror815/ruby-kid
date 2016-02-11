class AccountConfirmationController < ApplicationController

  layout 'markup'

  before_filter :check_user, except: [:account_confirmed]

  def index

  end

  def credit_card
    @token = generate_token
    @user_location = auth_user.primary_user_location
  end

  def driver_license
    logger.info "| auth_user #{auth_user}"
  end

  ##
  # Required params:
  #   driver_license_image or user[driver_license_image]
  def upload_driver_license
    image = params[:user] ? params[:user][:driver_license_image] : params[:driver_license_image]
    logger.info "| auth_user #{auth_user}"
    logger.info "| params #{params}"
    logger.info "| image #{image.class}"
    auth_user.driver_license_image = image
    auth_user.save
    render 'driver_license_uploaded'
  end

  def authorize_payment
    nonce = params[:payment_method_nonce]
    if nonce.nil?
      return redirect_to :users_dashboard
    end

    amount = "1.0" 
    if Rails.env.test?
      amount = params[:test_amount] || amount
    end

    result = Braintree::Transaction.sale(
      :amount => amount,
      :payment_method_nonce => nonce,
      :options => {
        submit_for_settlement: true
      }
    )

    if result.success?
      if auth_user.confirm_account!
        render action: :account_confirmed
      else
        flash[:error] = "Something went wrong. Please contact support."
        render action: :index
      end
    else
      flash[:error] = "Unable to charge card."
      render action: :index
    end
  end

  def account_confirmed
    if @result.nil?
      redirect_to :root
    end
  end

  private 

  def generate_token
    Braintree::ClientToken.generate
  end

  # User must be a parent who doesn't have account_confirmed.  Also checks the entered user_location has changed.
  def check_user
    if !auth_user.is_a?(Parent) || auth_user.account_confirmed
      logger.info " --> #{auth_user.class} (account_confirmed? #{auth_user.try(:account_confirmed)}) redirecting away from acount conf."
      ::Users::Notifications::NeedsAccountConfirm.sent_to(auth_user).delete_all if auth_user && auth_user.account_confirmed
      return redirect_to notifications_path
    end

    if auth_user.primary_user_location && (user_location_h = params.delete(:user_location) )
      new_user_location = ::Users::UserLocation.new(user_location_h)
      unless auth_user.primary_user_location.is_eq?(new_user_location)
        new_user_location.user_id = auth_user.id
        new_user_location.reviewed = false
        new_user_location.save
      end
    end
  end
end
