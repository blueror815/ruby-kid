##
# Common operations handled by parents, so needs authentication, permission checking, and limitiation.
# An instance variable would be set for checking and its name will follow standard style according to model name, 
# for example, UserLocation would be set to @user_location
module Users
  module HandledByParent

    def self.included(klass)
      klass.before_filter :verify_current_user, :only => [:show, :update, :destroy]
      klass.before_filter :clean_params_for_save!, :only => [:create, :update]
    end

    protected
    
    # Find referred record first. Check current user's permission to modify it.
    def verify_current_user
      instance_variable_set '@' + resource_name, resource.find_by_id(params[:id])
      if resource_instance.nil?
        flash[:error] = "Cannot find the requested record."
        redirect_to(action: 'index') && return
      else
        unless auth_user.is_a?(Parent) # Perhaps rule might change, so child could edit
          flash[:error] = "You do not have permission to access this."
          redirect_to(action: 'index') && return
        else

          # Avoid hack to change address of someone else's
          if params[resource_param_name].is_a?(Hash)
            params[resource_param_name].delete(:user_id)
            params[resource_param_name].delete('user_id')
          end
        end
      end
    end

    # Filter out mass-assign params that would invoke error.
    def clean_params_for_save!
      if params[resource_param_name].present?
        params[resource_param_name].delete(:id)
        params[resource_param_name].delete(:user_id)
      end
    end

    ##################
    # Accessing methods 
    
    ##
    # Help to pick the right, actually used nested-scope model parameter name, for examples, could be either users_user_location or user_location
    def resource_param_name
      @resource_param_name ||= params[resource_name.to_sym].present? ? resource_name.to_sym : ('users_' + resource_name).to_sym
    end

    # Model class
    def resource
      @@resource ||= self.class.to_s.gsub('Controller', '').singularize.constantize
    end

    # Model class name underscored
    def resource_name
      @@resource_name ||= self.class.to_s.split('::').last.gsub('Controller', '').singularize.underscore
    end
    
    def resource_instance
      self.instance_variable_get '@' + resource_name
    end

  end
end