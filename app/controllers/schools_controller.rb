class SchoolsController < ApplicationController

  skip_before_filter :verify_auth_user, only: [:index, :show, :new, :create]

  before_filter :check_permission, only: [:update, :destroy, :edit]
  before_filter :admin_set_schools, only: [:admin]

  # bc I'm not logging in everytime to test - AT
  # before_filter :verify_admin!, only: [:admin, :admin_show, :edit, :update, :destroy]
  
  # GET /schools
  # GET /schools.json

  def index
    # @schools = ::Schools::School.limit(50)
    @page_title = 'Schools'
    
    if params[:query].present?
      @page_title << ': ' + params[:query].strip
    end
    if params[:state].present?
      @page_title << ': ' + params[:state].strip + ' state'
    end
    if params[:zip].present?
      @page_title << " within zip-code #{params[:zip]}"
    end

    @schools_search = ::Schools::School.build_search(params)
    @schools_search.execute
    @schools = @schools_search.results
    unless request.xhr?
      @schools_gmap_hash = Gmaps4rails.build_markers(@schools) do |_school, marker|
        marker.lat _school.latitude
        marker.lng _school.longitude
        marker.title _school.name.titleize
        marker.infowindow _school.full_address
      end
    end

    respond_to do |format|
      format.js
      format.html{
        #for now, let's not keep it as a redirect to keep stupid people out.
        redirect_to root_path
      }
      format.json { render json: @schools }
    end
  end
    
  # GET /schools/1
  # GET /schools/1.json
  def show
    @school = ::Schools::School.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @school }
    end
  end

  # GET /schools/new
  # GET /schools/new.json
  def new
    @school = ::Schools::School.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @school }
    end
  end

  # GET /schools/1/edit
  def edit
    @school = ::Schools::School.find(params[:id])
  end

  # POST /schools
  # POST /schools.json
  def create
    @school = ::Schools::School.new(params[:school])

    respond_to do |format|
      if @school.save
        format.html { redirect_to school_path(@school), notice: 'School was successfully created.' }
        format.json { render json: @school }
      else
        format.html { render action: "new" }
        format.json { render json: { errors: @school.errors.first.join(' '), success: false } }
      end
    end
  end

  # PUT /schools/1
  # PUT /schools/1.json
  def update
    @school = ::Schools::School.find(params[:id])

    respond_to do |format|
      if @school.update_attributes(params[:schools])
        format.html { redirect_to @school, notice: 'School was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @school.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /schools/1
  # DELETE /schools/1.json
  def destroy
    @school = ::Schools::School.find(params[:id])
    @school.destroy

    respond_to do |format|
      format.html { redirect_to schools_path }
      format.json { head :no_content }
    end
  end

  # GET /schools/admin
  def admin
 
  end

  # GET /schools/admin/1
  # GET /schools/admin/1.json
  def admin_edit
      @school = ::Schools::School.find(params[:id])
     
      #find the next school to show for 'Skip'
      invalidated_schools = ::Schools::School.search_invalidated
      @next_school = invalidated_schools[(invalidated_schools.find_index(@school) + 1) % invalidated_schools.size]
      
      @num_students = Hash.new
      @num_students[@school.id] = ::Schools::SchoolGroup.student_count(@school)
      
      @nearby_schools = ::Schools::School.build_search(@school).execute.results
      @nearby_schools.each do |nearby_school|
          @num_students[nearby_school.id] = ::Schools::SchoolGroup.student_count(nearby_school)
      end

      @nearby_schools.sort_by! { |school| school.name }
  end

  # POST /schools/admin/:id
  def admin_update
     school_params = params[:school]
     school_params[:id] = params[:id]
     @school = ::Schools::School.find(school_params[:id])

     #find the next school to show after update
     invalidated_schools = ::Schools::School.search_invalidated
     @next_school = invalidated_schools[(invalidated_schools.find_index(@school) + 1) % invalidated_schools.size]

     unless school_params[:id].present? && school_params[:name].present? && school_params[:city].present? && school_params[:state].present? && school_params[:zip].present? && school_params[:country].present?
         return
     end

     zip_code = ::Geocode::ZipCode.search_by_zip_code(school_params[:zip] ).first
     
     if zip_code.nil?
        # either bad zip entered or not in zip_code table
     else
         school_params[:latitude] = zip_code.latitude
         school_params[:longitude] = zip_code.longitude
         school_params[:validated_admin] = true
         @school = ::Schools::School.find(school_params[:id])
         @school.update_attributes(school_params)
     end
    
     redirect_to schools_admin_edit_path(@next_school)
  end

  # DELETE /schools.admin/:id
  def admin_destroy

    if params[:school].nil?
        @users = ::User::User.where("current_school_id= #{params[:id]}") 
        @users.to_a.each do |user|
            user.update_attribute(:current_school_id, params[:nearby_school_id])
        end
    end
    
    @school = ::Schools::School.find(params[:id])
    
    invalidated_schools = ::Schools::School.search_invalidated
    @next_school = invalidated_schools[(invalidated_schools.find_index(@school) + 1) % invalidated_schools.size]
    
    @school.destroy
    redirect_to schools_admin_edit_path(@next_school)
  end 
  
  protected

  def check_permission
    if @school
      if auth_user.nil? || auth_user.is_a?(::Admin) == false
        flash[:error] = "You do not have permission to access this."
      end
    end

    if flash[:error].present?
      respond_to do |format|
        format.json { render( status: 401, json: make_json_status_hash(false) ) && return }
        format.html { redirect_to(schools_path) && return }
      end
    end
  end

  def admin_set_schools
      @schools = ::Schools::School.search_invalidated(params)
      @schools.paginate(:page => params[:page], :per_page => 20)
      @schools_students = Hash.new
      @schools.each do |school|
          @schools_students[school.id] = ::Schools::SchoolGroup.student_count(school) 
      end
  end
end
