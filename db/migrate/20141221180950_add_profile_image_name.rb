class AddProfileImageName < ActiveRecord::Migration
  def up
    add_column_unless_exists :users, :profile_image_name, :string, length: 56
  end

  def down
    remove_column_if_exists :users, :profile_image_name
  end
end
