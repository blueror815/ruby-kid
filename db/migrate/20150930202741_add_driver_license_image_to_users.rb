class AddDriverLicenseImageToUsers < ActiveRecord::Migration
  def change
    add_column_unless_exists :users, :driver_license_image, :string, length: 255
  end
end
