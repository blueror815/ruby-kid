class AddDeviceTokenToUsers < ActiveRecord::Migration
  def change
    add_column_unless_exists :users, :device_token, :string, length: 191
  end
end
