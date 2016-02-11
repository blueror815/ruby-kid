class AddProfileImageToUsers < ActiveRecord::Migration
  def change
    add_column_unless_exists :users, :profile_image, :string, length: 255, null: true
  end
end
