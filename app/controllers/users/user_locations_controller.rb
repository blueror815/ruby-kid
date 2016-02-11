module Users
  class UserLocationsController < ApplicationController

    include HandledByParent


    # GET /user_locations
    # GET /user_locations.json
    def index
      @user_locations = ::Users::UserLocation.where(user_id: auth_user.id).order('is_primary desc')
      @page_title = 'Your Addresses'

      respond_to do|format|
        format.html
        format.json { render json: @user_locations }
      end
    end

    # GET /user_locations/1
    # GET /user_locations/1.json
    def show
      index
    end

    # GET /user_locations/new
    # GET /user_locations/new.json
    def new
      @user_location = ::Users::UserLocation.new

      respond_to do |format|
        format.html { render 'index.html.haml' } # new.html.erb
        format.json { render json: @user_location }
      end
    end


    ##
    # Currently a user only needs one single location entered, so this would override existing user location is exists.
    # Post parameters may also include extra parameter [:phone_number] for API's convenience to join contact calls into one,
    # and Users::UserPhone will be made as primary home phone.
    # extra params
    #   :phone_number <String> creating a new UserPhone for current user
    #   :user_phones <Array of Hash of UserPhone attributes> replacement of current user's existing user_phones
    #   :user_locations <Array of Hash of UserLocation attributes> replacement of current user's existing user_locations
    #
    # POST /user_locations
    # POST /user_locations.json
    def create
      @user_location = auth_user.primary_user_location || auth_user.user_locations.last || ::Users::UserLocation.new
      loc_params = params[resource_param_name]
      if loc_params.present?
        @user_location.attributes = loc_params.select{|k,v| ![:id].include?(k) }
        @user_location.user_id = auth_user.id
      end

      if (user_locations = params[:user_locations] || params['user_locations']).present?
        new_user_locations = user_locations.collect do|p|
          loc = ::Users::UserLocation.new(p)
          loc.user_id = auth_user.id
          loc
        end
        if new_user_locations.present?
          ::Users::UserLocation.where(user_id: auth_user.id).delete_all
          auth_user.user_locations = new_user_locations
          auth_user.save
          @user_location = new_user_locations.first
        end
      end
      logger.info "| valid location? #{@user_location.valid?} : #{@user_location.errors.full_messages}"
      respond_to do |format|
        if @user_location.save

          save_phone_number

          format.html { redirect_to next_after_save, notice: 'Address was successfully created.' }
          format.json { render json: {success: true, user_location: @user_location.as_json }, status: :created }
        else
          format.html { render action: "new" }
          format.json { render json: {success: false, errors: @user_location.errors.messages}, status: :unprocessable_entity  }
        end
      end
    end

    # PUT /user_locations/1
    # PUT /user_locations/1.json
    def update

      save_phone_number

      respond_to do |format|

        if @user_location.update_attributes(params[resource_param_name])
          format.html { redirect_to next_after_save, notice: 'Address was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @user_location.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /user_locations/1
    # DELETE /user_locations/1.json
    def destroy
      @user_location.destroy

      respond_to do |format|
        format.html { redirect_to user_locations_url }
        format.json { head :no_content }
      end
    end

    protected

    def save_phone_number
      phone = nil
      if params[:phone_number].present?
        phone = ::Users::UserPhone.new(phone_type: ::Users::UserPhone::PhoneType::HOME, number: params[:phone_number].strip, is_primary: true)
        phone.user_id = auth_user.id
      elsif (user_phones = params[:user_phones] || params['user_phones']).present?
        already_has_primary = false
        new_user_phones = user_phones.collect do|p|
          phash = p.is_a?(Hash) ? p : {phone_type: ::Users::UserPhone::PhoneType::HOME, number: p.to_s, is_primary: !already_has_primary }
          already_has_primary = true
          ::Users::UserPhone.new(phash.merge({user_id: auth_user.id }) )
        end
        if new_user_phones.present?
          ::Users::UserPhone.where(user_id: auth_user.id).delete_all
          auth_user.user_phones = new_user_phones
          auth_user.save
        end
      end
      phone.save if phone
      phone
    end

    # @return <String>
    def next_after_save
      @child = Child.find_by_id(params[:child_id]) if params[:child_id]
      if @child && params[:initial_reg]
        child_school_path(id: @child.id, initial_reg: params[:initial_reg])
      else
        user_locations_path
      end
    end

  end
end
