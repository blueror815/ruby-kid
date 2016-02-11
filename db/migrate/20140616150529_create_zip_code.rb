class CreateZipCode < ActiveRecord::Migration
  def up
    create_table_unless_exists :zip_codes do|t|
      t.string :zip, null: false, length: 48
      t.string :state_type, default: 'STANDARD', length: 24
      t.string :primary_city, null: false, length: 48
      t.string :acceptable_cities
      t.string :unacceptable_cities
      t.string :state, null: false, length: 48
      t.string :county, length: 48
      t.integer :timezone
      t.string :area_codes
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.string :world_region
      t.string :country, default: 'United States'
    end
    
    add_index_unless_exists :zip_codes, :zip
    add_index_unless_exists :zip_codes, :primary_city
    add_index_unless_exists :zip_codes, :state
    add_index_unless_exists :zip_codes, [:country, :state]
    add_index_unless_exists :zip_codes, :timezone
    
  end

  def down
    drop_table_if_exists :zip_codes
  end
end
