module Users
  class UserTracking < ActiveRecord::Base

    self.table_name = 'user_trackings'

    attr_accessible :user_id, :ip, :system, :browser, :continent, :country, :city, :state, :zip, :timezone, :login_at, :logout_at

    belongs_to :user

    ##
    # @user <User>
    # @request <ActionDispatch::Request>
    # @login_or_logout <symbol either :login or :logout> optional; specify to set either login or logout time of user
    # @more_data <Hash> optional; secondary data that as alternative to geo data, for example, if location not found, may
    #   use the :time_zone captured from browser
    # @return <Users::UserTracking>

    def self.record_user_request!(user, request, login_or_logout = nil, more_data = {} )
      return nil if user.nil?
      tracking = user.user_tracking || new
      tracking.user_id = user.id
      if login_or_logout == :login
        tracking.login_at = Time.now
      elsif login_or_logout == :logout
        tracking.logout_at = Time.now
      end
      user_agent = request.env['HTTP_USER_AGENT']
      browser = Browser.new(:ua => user_agent, :accept_language => "en-us")
      location = ::GeoData.city_db.lookup(request.remote_ip)
      tracking.attributes = {
          ip: request.remote_ip, system: browser.platform, browser: user_agent,
          continent: location.continent.name, country: location.country.name,
          city: location.city.name, state: location.subdivisions.first.try(:name), zip: location.postal.code,
          timezone: location.location.time_zone || more_data[:time_zone]
        }
      tracking.save
      tracking
    end
  end
end