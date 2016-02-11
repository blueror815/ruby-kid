module Geocode
  class ZipCode < ActiveRecord::Base
    self.table_name = 'zip_codes'

    attr_accessible :zip, :state_type, :primary_city, :acceptable_cities, :unacceptable_cities, :state, :county, :timezone, :area_codes, :latitude, :longitude, :world_region, :country

    validates_presence_of :zip, :primary_city, :state, :country # , :timezone

    CSV_HEADER = %w(zip type primary_city acceptable_cities unacceptable_cities state county timezone area_codes latitude longitude world_region country)

    TIMEZONE_NAMES_TO_GMT_MAPPING = {
        "america/puerto_rico" => -4,
        "america/new_york" => -5,
        "america/kentucky/louisville" => -5,
        "america/kentucky/monticello" => -5,
        "america/indiana/indianapolis" => -5,

        "america/indiana/winamac" => -5,
        "america/indiana/vevay" => -5,
        "america/indiana/marengo" => -5,
        "america/indiana/vincennes" => -5,
        "america/indiana/petersburg" => -5,

        "america/indiana/knox" => -6,
        "america/indiana/tell_city" => -6,
        "america/chicago" => -6,
        "america/detroit" => -6,
        "america/menominee" => -6,
        "america/north_dakota/center" => -6,
        "america/denver" => -7,
        "america/boise" => -7,
        "america/phoenix" => -7,
        "america/shiprock" => -7,
        "america/los_angeles" => -8,
        "america/anchorage" => -9,
        "america/nome" => -9,
        "america/yakutat" => -9,
        "america/juneau" => -9,
        "pacific/honolulu" => -10,
        "america/palau" => 9,
        "america/guam" => 10,
        "america/marshall_islands" => 12
    }

    # Intended for HTML options
    TIMEZONE_LIST_MINIMIZED = [
        ["Puerto Rico (GMT -4)", -4],
        ["East - New York (GMT -5)", -5],
        ["Central - Kentucky (GMT -6)", -6],
        ["Mountain - Colarado (GMT -7)", -7],
        ["West - Los Angeles (GMT -8)", -8],
        ["Alaska (GMT -9)"],
        ["Hawaii (GMT -10)", -10],
        ["Samoa (GMT -11)", -11],
        ["Palau (GMT 9)", 9],
        ["Guam (GMT +10)", 10],
        ["Marshall Islands", 12]
    ]

    ZIP_CODE_LIST = all.collect(&:zip).sort

    ZIP_CODE_FORMAT_REGEXP = /([\w]{4,5})[\s\-]+(\w+)/i
    USA_ZIP_CODE_FORMAT_REGEXP = /([\d]{4,5})([\s\-]+(\d+))?/i # number only

    def self.is_valid_usa_zip_code?(zip = '')
      USA_ZIP_CODE_FORMAT_REGEXP.match(zip.strip).present?
    end
    
    def self.standardize_zip_code(zip = '')
      m = ZIP_CODE_FORMAT_REGEXP.match(zip.strip)
      return zip if m.nil?
      m[1].length < 5 ? format("%05d", m[1] ) : m[1]
    end

    # Sanitize the zip argument to make search with a standard form of zip code. The result includes
    # those with matching zip at start and substrings like regional zip codes.
    # @return <Array of Geocode::ZipCode
    def self.search_by_zip_code(zip)

      where("zip LIKE '#{standardize_zip_code(zip)}%'", ).limit(10)
    end

    ########################
    # Instance Methods

    def as_json(options = nil)
      super((options || {}).merge(only: [:zip, :primary_city, :state, :timezone, :area_codes, :longitude, :latitude] ))
    end


    #################################

    # Header in format of +CSV_HEADER+

    def self.import_from_csv_file(file_path)
      CSV.foreach(file_path) do |row|
        next if row[0].downcase == 'zip' # header row
        h = {}
        CSV_HEADER.each_with_index do |col, idx|
          if col == 'type'
            h[:state_type] = row[idx]
          elsif col == 'timezone'
            if row[idx].present?
              h[col.to_sym] = TIMEZONE_NAMES_TO_GMT_MAPPING[row[idx].downcase]
            end
          else
            h[col.to_sym] = row[idx]
          end
        end
        zrecord = new(h)
        if zrecord.valid?
          zrecord.save
        else
          CUSTOM_LOGGER.warn "** Invalid: #{row.inspect}"
          CUSTOM_LOGGER.warn "  #{zrecord.errors.full_messages}"
        end
      end
    end

    # Some data imports may have states and not timezone set. This will try to find other timezone-validly-set record 
    # in the same state.
    def self.fix_null_timezones
      where("timezone is null").each do |z|
        if (z.state.present?) then
          same_state=Geocode::ZipCode.where("state='#{z.state}' and timezone is not null").first
          z.update_attribute(:timezone, same_state.timezone) if same_state.present?
        end
      end

    end
  end
end