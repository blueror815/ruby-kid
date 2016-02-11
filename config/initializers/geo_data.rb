##
# Adapter to query location data like GeoIP of MaxMind

class GeoData

  MAX_MIND_CITY_DB_PATH = './doc/data/GeoLite2-City.mmdb'.freeze
  MAX_MIND_COUNTRY_DB_PATH = './doc/data/GeoLite2-Country.mmdb'.freeze

  ##
  # @return <MaxMindDB::Client>
  def self.city_db
    @max_mind_city_db ||= MaxMindDB.new(MAX_MIND_CITY_DB_PATH)
  end
end