
# Parsing survey data files provided on http://nces.ed.gov/surveys/pss/pssdata.asp.

module Parsers
  class PublicGradeSchoolsFromEdGov
    
    require 'csv'
    
    DATA_COLUMNS_TO_ATTRIBUTES_MAPPING = {
        :SCHNAM09 => :name,
        :LSTREE09 => :address,
        :LCITY09 => :city,
        :LSTATE09 => :state,
        :LZIP09 => :zip,
        :LZIP409 => :zip_extension,
        :LATCOD09 => :latitude,
        :LONCOD09 => :longitude
        }
    
    ATTRIBUTES_TO_COLUMN_INDICES_MAPPING = {
        :name => 7,
        :address => 14,
        :city => 15,
        :state => 16,
        :zip => 17,
        :zip_extension => 18,
        :latitude => 22,
        :longitude => 23
        }
    
    
    # Reads the data file's data line by line and parses into Hash of attributes and yields to block.
    # Yields to the block a Hash of attributes (latitude and longitude converted to floats)
    def self.read(file_path)
      CSV.foreach(file_path, :col_sep => ",", :encoding => 'ISO-8859-1') do|cols|
        attr = {}
        ATTRIBUTES_TO_COLUMN_INDICES_MAPPING.each_pair do|aname, col_index|
          attr[aname] = [:latitude, :longitude].include?(aname) ? cols[col_index].to_f : cols[col_index]
        end
        attr[:zip] << '-' + attr[:zip_extension] if attr[:zip_extension].present?
        attr.delete(:zip_extension)
        yield attr
      end
    end
    
    def self.load(file_path)
      read(file_path) do|attr|
        begin
          ::Schools::PublicGradeSchool.create(attr)
          # puts attr[:name]
        rescue Exception => parse_e
          puts "** #{parse_e.message}"
        end
      end
    end
  end
end