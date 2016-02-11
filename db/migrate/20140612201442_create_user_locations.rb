class CreateUserLocations < ActiveRecord::Migration
  def change
    create_table :user_locations do |t|
      t.integer :user_id
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.string :country, :default => 'United States'
      t.float :latitude
      t.float :longitude
      t.boolean :is_primary, :default => false

    end
    
    add_index :user_locations, :user_id
    add_index :user_locations, [:user_id, :is_primary]
  end
end
