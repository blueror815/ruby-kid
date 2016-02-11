class AddCountries < ActiveRecord::Migration
  def change
    create_table_unless_exists "countries", :id => false, :force => true do |t|
      t.string "iso", :limit => 2, :primary_key => true, :null => false
      t.string "name", :limit => 80
      t.string "printable_name", :limit => 80
      t.string "iso3", :limit => 3
      t.integer "numcode", :limit => 6
    end
  end
end
