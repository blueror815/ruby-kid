class DevicesController < ApplicationController

  before_filter :find_current_device, only: [:show, :edit, :update, :destroy]

  # GET /devices
  # GET /devices.json
  def index
    @devices = Device.where(:user_id, auth_user.id)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @devices }
    end
  end

  # GET /devices/1
  # GET /devices/1.json
  def show

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @device }
    end
  end

  # GET /devices/new
  # GET /devices/new.json
  def new
    @device = Device.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @device }
    end
  end

  # GET /devices/1/edit
  def edit
  end

  # POST /devices
  # POST /devices.json
  def create
    @device = Device.where(user_id: auth_user.id, push_token: params[:device][:push_token] ).first if params[:device] && params[:device][:push_token].present?
    @device ||= Device.new(params[:device])
    @device.user_id = auth_user.id
    
    respond_to do |format|
      if @device.save
        format.html { redirect_to @device, notice: 'Device was successfully created.' }
        format.json { render json: { device: @device.as_json, success: true } }
      else
        flash[:error] = @device.errors.values.join('.  ')
        puts "  Errors: #{@device.errors.keys}"

        format.html { render action: "new" }
        format.json { render json: make_json_status_hash(false)  }
      end
    end
  end

  # PUT /devices/1
  # PUT /devices/1.json
  def update

    respond_to do |format|
      if @device.update_attributes(params[:device])
        format.html { redirect_to @device, notice: 'Device was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /devices/1
  # DELETE /devices/1.json
  def destroy
    @device.destroy

    respond_to do |format|
      format.html { redirect_to devices_url }
      format.json { head :no_content }
    end
  end
  
  private
  
  def find_current_device
    @device = Device.find_by_id(params[:id])
    unless @device
      flash[:error] = "The requested device cannot be found."
      respond_to do|format|
        format.html { redirect_to(devices_path) }
        format.json { render json: {:error => flash[:error] }  }
      end
    end
  end
end
