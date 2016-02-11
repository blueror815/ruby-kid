require 'doorkeeper'

Doorkeeper.configure do
  orm :active_record
  
  access_token_expires_in nil

  resource_owner_from_credentials do |routes|
    user = User.find_for_database_authentication(:user_name => params[:username])
    if user.nil?
	    user = User.find_for_database_authentication(:email => params[:username])
    end

    user if user && user.valid_password?(params[:password])
  end

  grant_flows %w(password)
end
