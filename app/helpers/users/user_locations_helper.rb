module Users
  module UserLocationsHelper
    
    # These methods are needed for use in device/registrations/_form
    
    def resource
      auth_user
    end
    
    def resource_name
      'user'
    end
  end
end