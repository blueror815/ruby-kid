# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

#http://panupan.com/2013/01/18/seed-your-rails-app-by-importing-from-sql/
#keep the development_db_dump.sql file up to date and rake db:seed will work as expected.

unless Rails.env.production?
  connection = ActiveRecord::Base.connection
  connection.tables.each do |table|
    connection.execute("TRUNCATE #{table}") unless table == "schema_migrations"
  end
   
  # - IMPORTANT: SEED DATA ONLY
  # - DO NOT EXPORT TABLE STRUCTURES
  # - DO NOT EXPORT DATA FROM `schema_migrations`
  sql = File.read('doc/data/development_db_dump.sql')
  statements = sql.split(/;$/)
  statements.pop  # the last empty statement
 
  ActiveRecord::Base.transaction do
    statements.each do |statement|
      connection.execute(statement)
    end
  end
end