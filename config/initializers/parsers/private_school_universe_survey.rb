
# Parsing survey data files provided on http://nces.ed.gov/surveys/pss/pssdata.asp.

module Parsers
  class PrivateSchoolUniverseSurvey
    
    require 'csv'
    
    DATA_COLUMNS_TO_ATTRIBUTES_MAPPING = {
        :pinst => :name,
        :paddrs => :address,
        :pcity => :city,
        :pstabb => :state,
        :pzip => :zip,
        :pzip4 => :zip_extension,
        :latitude10 => :latitude,
        :longitude10 => :longitude
        }
    
    ATTRIBUTES_TO_COLUMN_INDICES_MAPPING = {
        :name => 198,
        :address => 199,
        :city => 200,
        :state => 201,
        :zip => 202,
        :zip_extension => 203,
        :latitude => 214,
        :longitude => 215
        }
    
    
    # Reads the data file's data line by line and parses into Hash of attributes and yields to block.
    # Yields to the block a Hash of attributes (latitude and longitude converted to floats)
    def self.read(file_path)
      CSV.foreach(file_path, :col_sep => "\t", :encoding => 'ISO-8859-1') do|cols|
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
        ::Schools::PrivateGradeSchool.create(attr)
        puts attr[:name]
      end
    end
  end
end