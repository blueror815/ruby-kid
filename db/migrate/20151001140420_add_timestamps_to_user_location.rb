class AddTimestampsToUserLocation < ActiveRecord::Migration
  def change
    add_column_unless_exists :user_locations, :updated_at, :datetime
    add_column_unless_exists :user_locations, :created_at, :datetime
    add_column_unless_exists :user_locations, :reviewed, :boolean, default: true
    add_index_unless_exists :user_locations, :reviewed

    begin
      ::Users::UserLocation.where("created_at IS NULL").each do|loc|
        user_created_at = loc.user.created_at
        loc.created_at = user_created_at
        loc.updated_at = user_created_at
        loc.save
      end
    rescue Exception => e # Error might occur if database alteration too slow.
    end
  end
end
