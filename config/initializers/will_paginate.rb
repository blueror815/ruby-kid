#this is to get Will_Paginate to work with activeAdmin

#source: https://github.com/mislav/will_paginate/issues/174

# config/initializers/will_paginate.rb
if defined?(WillPaginate)
  module WillPaginate
    module ActiveRecord
      module RelationMethods
        alias_method :per, :per_page
        alias_method :num_pages, :total_pages
      end
    end
  end
end