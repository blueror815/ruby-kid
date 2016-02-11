class AddPrimaryUserLocationToUsers < ActiveRecord::Migration
  def up
    
    add_column_unless_exists :users, :primary_user_location_id, :integer
  end

  def down
  end
end
