module Users
  class UserLocation < ActiveRecord::Base

    self.table_name = 'user_locations'

    attr_accessible :address, :address2, :city, :country, :latitude, :longitude, :state, :zip, :is_primary

    include IsPrimary

    belongs_to :user

    validates_presence_of :address, :city
    validate :validate_zip_or_state

    before_save :set_defaults!
    before_save :set_gps_location!
    after_create :after_auto_settings
    after_save :synch_user_info

    # If has existing primary_user_location_id, replace that one.  Otherwise create new primary.
    def self.set_primary_for_user!(user, attributes = {})
      if attributes.present?
        current_primary = user.primary_user_location_id ? user.primary_user_location : new(is_primary: true)
        current_primary ||= new(is_primary: true)
        current_primary.attributes = attributes
        current_primary.user_id ||= user.id
        current_primary.save
      end
    end

    ##
    # With either presence of either city or state
    def validate_zip_or_state
      # check format of zip and state
      enough = false
      if zip.present? && ::Geocode::ZipCode.is_valid_usa_zip_code?(zip)
        #
        enough = true
      elsif state.present?
        if ::Geocode::State::USA_STATE_CODES_TO_NAMES_MAP.include?(state.strip.upcase)
          enough = true
        else
          self.errors.add(:state, "Invalid State")
        end
      end
      unless enough
        self.errors.add(:zip, "Required to set either State or Zip Code")
      end
    end

    ##
    # If not specified, default country to US, is_primary to true, and set state according to the zip code
    def set_defaults!
      self.country = 'United States' if self.country.blank?
      self.is_primary = true if self.is_primary.nil?
      if !self.is_primary && new_record?
        self.reviewed = false
      end
      if state.blank? && ::Geocode::ZipCode.is_valid_usa_zip_code?(zip)
        zips = ::Geocode::ZipCode.search_by_zip_code(zip)
        if zips.present?
          self.state = zips.first.state
        end
      end
    end

    ##
    # From the address in valid format, query for longitude and latitude for real GPS location
    def set_gps_location!

    end

    ##################
    # Info methods

    def is_eq?(other_user_location)
      %w|address address2 city state zip country|.all? do|attr|
        self[attr].to_s.strip_naked == other_user_location[attr].to_s.strip_naked
      end
    end

    def to_s
      "<UserLocation of #{user_id}: #{attributes.select { |k| [:address, :city, :state, :zip].include?(k.to_sym) } }"
    end

    def city_state
      city.titleize + ', ' + state.upcase
    end

    def as_json(options = nil)
      super((options || {}).merge(only: [:id, :address, :address2, :city, :state, :zip, :country, :latitude, :longitude] ))
    end

    private

    ##
    # Checks if the child has address entered but parent does not, clone for the parent also
    def after_auto_settings
      if self.user.is_a?(Child) && self.user.parents.sum { |parent| parent.user_locations.count }.zero?
        self.user.parents.each do |parent|
          puts "  clone child address for parent #{parent.user_name}"
          new_location = self.clone
          new_location.user_id = parent.id
          new_location.save
        end
      end

    end

    def synch_user_info
      if self.is_primary && self.user.primary_user_location_id != self.id
        self.user.update_attribute(:primary_user_location_id, self.id)
        if self.user.is_a?(Parent)
          children_ids = self.user.children.to_a.find_all{|c| c.primary_user_location_id.to_i == 0 }.collect(&:id)
          User.where(id: children_ids).update_all(primary_user_location_id: self.id)
        end
      end
    end
  end
end