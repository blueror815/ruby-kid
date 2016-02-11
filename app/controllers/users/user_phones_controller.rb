module Users
  class UserPhonesController < ApplicationController

    include HandledByParent

    def index
      @user_phones = ::Users::UserPhone.where(user_id: auth_user.id).order('is_primary desc')
      @page_title = "Your Phone Numbers"

      respond_to do |format|
        format.html
        format.json { render json: @user_phones }
      end
    end

    def new
      index
    end

    def create
      @user_phone = ::Users::UserPhone.new(params[resource_param_name])
      @user_phone.user_id = auth_user.id

      @user_phones = ::Users::UserPhone.where(user_id: auth_user.id).order('is_primary desc').to_a

      respond_to do |format|
        if @user_phone.save
          @user_phones.insert(0, @user_phone)
          format.js
          format.html { redirect_to user_phones_path, notice: 'Phone was successfully created' }
          format.json { render json: @user_phone, status: :created, location: @user_phone }
        else
          flash[:error] = @user_phone.errors.full_messages.join(". ")
          
          puts "------ bad: #{@user_phone.errors.full_messages}"
          @user_phones.insert(0, @user_phone)
          
          format.js
          format.html { render action: "index" }
          format.json { render json: @user_phone.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      @user_phone_is_primary_changed = params[resource_param_name].nil? ? false : ( @user_phone.is_primary !=  params[resource_param_name][:is_primary] )
      respond_to do |format|
        @user_phone.attributes = params[resource_param_name] if params[resource_param_name].present?
        if @user_phone.save
          if @user_phone_is_primary_changed == true
            @user_phones = ::Users::UserPhone.where(user_id: auth_user.id).order('is_primary desc').to_a
          end
          format.js
          format.html { redirect_to user_phones_path, notice: 'Phone was successfully updated' }
          format.json { head :no_content }
        else
          flash[:error] = @user_phone.errors.full_messages.join(". ")
          format.js
          format.html { render action: "index" }
          format.json { render json: @user_location.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @user_phone.destroy
      respond_to do |format|
        format.js
        format.html { redirect_to(action: 'index', notice: 'Phone was successfully deleted.') }
        format.json { head :no_content }
      end
    end
  end
end