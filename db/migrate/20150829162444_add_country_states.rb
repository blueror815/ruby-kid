class AddCountryStates < ActiveRecord::Migration
  def change
    create_table_unless_exists "country_states", :force => true do |t|
      t.string "country_iso", :limit => 2
      t.string "code", :limit => 2
      t.string "name", :limit => 50
    end

    add_index_unless_exists "country_states", ["country_iso", "code"], :name => "country_iso_code"
    add_index_unless_exists "country_states", ["code"], :name => "idx_code"
  end
end
