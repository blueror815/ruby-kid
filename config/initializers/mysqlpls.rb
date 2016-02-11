# config/initializers/mysqlpls.rb
require 'active_record/connection_adapters/abstract_mysql_adapter'

#https://github.com/rails/rails/issues/9855
#fixes issues with index key being larger than 767 in strings with VARCHAR(255) on InnoDB engine tables 
#fixes in both rake db:migrate and rake db:test:prepare

module ActiveRecord
  module ConnectionAdapters
    class AbstractMysqlAdapter
      NATIVE_DATABASE_TYPES[:string] = { :name => "varchar", :limit => 191 }
    end
  end
end