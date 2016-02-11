class DropDeviceToken < ActiveRecord::Migration
  def up
    remove_column :users, :device_token
  end

  def down
  end
end
