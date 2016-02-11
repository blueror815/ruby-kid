module Schools
  class School < ActiveRecord::Base

    self.table_name = 'schools'
    cache_records :store => :shared, :key => "sch"
    self.inheritance_column = :_type_disabled
    attr_accessible :address, :city, :latitude, :longitude, :name, :state, :country, :zip, :validated_admin, :homeschool

    DEFAULT_DISTANCE_IN_KM = 50

    ##
    # Associations

    has_and_belongs_to_many :users
    has_many :school_registrations, class_name:'Schools::SchoolRegistration'

    ##
    # Scopes
    scope :not_validated_by_admin, conditions:{ validated_admin: false }

    #
    # Callbacks, validators

    before_save :set_defaults!

    validates_presence_of :name

    searchable(:if => :not_college?) do
      text :name
      text :address
      text :city
      string :state
      text :state_name
      text :zip
      latlon :location do
        Sunspot::Util::Coordinates.new(latitude, longitude)
      end

    end

    # Remove duplicate schools by country with matching name and zip
    def self.dedupe(country)
        # find all models and group them on keys which should be common
        grouped = where(country: country).group_by{|model| [model.name,model.country, model.zip] }
        grouped.values.each do |duplicates|
            # the first one we want to keep right?
            first_one = duplicates.shift # or pop for last one
            # if there are any more left, they are duplicates
            # so delete all of them
            duplicates.each{|double| double.destroy} # duplicates can now be destroyed
        end
    end


    def state_name
      ::Geocode::State::USA_STATE_CODES_TO_NAMES_MAP[state.upcase]
    end

    # Joined string of address, city, state and zip.
    def full_address
      [address.to_s.titleize, city.to_s.titleize, state.to_s].delete_if(&:blank?).join(', ') + ' ' + zip.to_s
    end

    def not_college?
      self.type.to_s.ends_with?('College') == false
    end

    ##
    # params <Hash>
    #   :query <String> search among name, city and state name of schools
    #   :
    #   <Sunspot::Search>
    def self.build_search(params)
      schools_search = Sunspot.new_search(::Schools::School) do
        paginate :page => params[:page] || 1, :per_page => (params[:limit] || 100)
      end

      params[:query] = params[:q] if params[:query].blank? && params[:q]
      if params[:query].present?
        params[:query] = CGI.unescape(params[:query])
        schools_search.build do
          fulltext params[:query].strip, fields: [:name, :city, :state_name] do
            boost_fields :name => 3.0, :city => 0.8, :state_name => 0.5
          end
        end
      end

      if params[:state].present?
        schools_search.build do
          with :state, params[:state].strip
        end
      end

      sort = params[:sort]
      sort_field, sort_order = sort.to_s.downcase.split(/[\s_]+/)

      if params[:zip].present?
        zip_code = ::Geocode::ZipCode.search_by_zip_code(params[:zip]).first
        schools_search.build do
          if zip_code
            if sort_field.to_s == 'location'
              params[:lon] = zip_code.longitude
              params[:lat] = zip_code.latitude
            end
            with(:location).in_radius(zip_code.latitude, zip_code.longitude, (params[:distance] || DEFAULT_DISTANCE_IN_KM).to_f ) # in km
          else
            fulltext ::Geocode::ZipCode.standardize_zip_code( params[:zip].strip ), fields: [:zip]
          end
        end

      elsif params[:lon].present? && params[:lat].present?
        distance = (params[:distance] || DEFAULT_DISTANCE_IN_KM).to_f
        puts "  spatial search: #{params[:lat]}, #{params[:lon]} w/in distance #{distance}"
        schools_search.build do
          with(:location).in_radius(params[:lat].to_f, params[:lon].to_f, distance)
        end
      end

      # puts "  sort_field #{sort_field}, params #{params.to_yaml}"
      schools_search.build do
        if sort_field.to_s == 'location' # && params[:lon].present? && params[:lat].present?
          order_by_geodist(:location, params[:lat].to_f, params[:lon].to_f)
        else
          order_by sort_field.to_sym, sort_order.to_sym
        end
      end if sort.present? && ItemsHelper.valid_sort?(sort)

      schools_search
    end

    ##
    # Results of schools will be saved
    # +current_location+ <Users::UserLocation>
    # @return <Array of Schools::School or whichever object having :zip or :state>
    def self.search_with_location(current_location = nil, params = {})
      zip = current_location.try(:zip) || params[:zip]
      zip_code = zip.present? ? Geocode::ZipCode.search_by_zip_code(zip).first : nil
      schools = nil
      schools = Schools::School.search {
        with(:location).in_radius(zip_code.latitude, zip_code.longitude, 4) # in km, 2.5 miles
        paginate :page=>1, :per_page=>50
      }.relation if zip_code

      if schools.blank?
        state = current_location.try(:state) || params[:state]
        schools = Schools::School.search {
          with(:state, state)
          paginate :page=>1, :per_page=>50
        }.relation if state
        puts " .. search schools w/ state #{state}"
      end
      schools
    end

    def self.search_invalidated(params = {})
        if params[:q].present?
            where("validated_admin=0 AND name LIKE :query", query: "%#{params[:q]}%").order('id desc')
        else
            where(validated_admin: 0).order('id desc')
        end
    end

    protected

    def set_defaults!
      self.type ||= ''
      self.address ||= ''
      self.city ||= ''
      self.zip ||= ''
      if self.zip.present? && (self.longitude.nil? || self.latitude.nil?)
        zip_code = Geocode::ZipCode.search_by_zip_code(zip).first
        if zip_code
          self.longitude = zip_code.longitude
          self.latitude = zip_code.latitude
        end
      end
    end

  end
end
