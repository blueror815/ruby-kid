module Users
  class PermissionsController < ApplicationController

    include HandledByParent
    
    before_filter :verify_current_parent, only: [:update, :destroy]
    
    def index
      @permissions = ::Users::Permission.where(user_id: auth_user.id).order('id desc')
      @page_title = "Your Permissions"

      respond_to do |format|
        format.html
        format.json { render json: @permissions }
      end
    end

    def new
      
    end

    def create
      @permission = ::Users::Permission.new(params[resource_param_name])
      @permission.user_id = auth_user.id

      @permissions = ::Users::Permission.where(user_id: auth_user.id).order('id desc').to_a

      respond_to do |format|
        if @permission.save
          @permissions.insert(0, @permission)
          format.js
          format.html { redirect_to user_phones_path, notice: 'Permission was successfully added' }
          format.json { render json: @permission, status: :created, sucess: true }
        else
          flash[:error] = @permission.errors.full_messages.join(". ")

          puts "------ bad: #{@permission.errors.full_messages}"
          @permissions.insert(0, @permission)

          format.js
          format.html { render action: "index" }
          format.json { render json: @permission.errors, status: :unprocessable_entity, success: false }
        end
      end
    end

    def update
      respond_to do |format|
        @permission.attributes = params[resource_param_name] if params[resource_param_name].present?
        if @permission.save
          format.js
          format.html { redirect_to user_phones_path, notice: 'Permission was successfully updated' }
          format.json { render json: @permission, sucess: true }
        else
          flash[:error] = @permission.errors.full_messages.join(". ")
          format.js
          format.html { render action: "index" }
          format.json { render json: @user_location.errors, status: :unprocessable_entity, success: false }
        end
      end
    end

    def destroy
      @permission.destroy
      respond_to do |format|
        format.js
        format.html { redirect_to(action: 'index', notice: 'Permission was successfully removed.') }
        format.json { head :no_content }
      end
    end

    private

    # Checks if referred permisson belongs to this parent's family.
    #
    def verify_current_parent
      if @permission
        unless auth_user.parent_of?( @permission.secondary_user )
          flash[:error] = "You do not have permission to access this."
          redirect_to(permissions_path) && return
        end
      end
    end

  end
end