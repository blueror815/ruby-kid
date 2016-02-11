
# Parsing survey data files provided on http://nces.ed.gov/surveys/pss/pssdata.asp.

module Parsers
  class CollegesAndUniversities
    
    require 'csv'
    
    DATA_COLUMNS_TO_ATTRIBUTES_MAPPING = {
        :INSTNM => :name,
        :ADDR => :address,
        :CITY => :city,
        :STABBR => :state,
        :ZIP => :zip,
        :LATITUDE => :latitude,
        :LONGITUD => :longitude
        }
    
    ATTRIBUTES_TO_COLUMN_INDICES_MAPPING = {
        :name => 1,
        :address => 2,
        :city => 3,
        :state => 4,
        :zip => 5,
        :latitude => 64,
        :longitude => 63
      }
    
    
    # Reads the data file's data line by line and parses into Hash of attributes and yields to block.
    # Yields to the block a Hash of attributes (latitude and longitude converted to floats)
    def self.read(file_path)
      CSV.foreach(file_path, :col_sep => ",", :encoding => 'ISO-8859-1') do|cols|
        attr = {}
        ATTRIBUTES_TO_COLUMN_INDICES_MAPPING.each_pair do|aname, col_index|
          attr[aname] = [:latitude, :longitude].include?(aname) ? cols[col_index].to_f : cols[col_index]
        end
        yield attr
      end
    end
    
    def self.load(file_path)
      read(file_path) do|attr|
        ::Schools::College.create(attr)
        puts attr[:name]
      end
    end
  end
end