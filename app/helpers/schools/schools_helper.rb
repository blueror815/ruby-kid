module Schools
  module SchoolsHelper
  
    SORT_FIELDS = [['Relevancy', ''], ['Distance', 'LOCATION'],
                   ['School Name', 'NAME ASC'], ['Zip Code', 'ZIP ASC'] ]
    def self.valid_sort?(sort)
      SORT_FIELDS.collect { |ar| ar[1] }.include?(sort.to_s.upcase)
    end

  end
end