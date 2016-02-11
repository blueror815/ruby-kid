class MakeDevicesPushTokenUnique < ActiveRecord::Migration
  def up
    change_table :devices do |t|
      t.change :push_token, :string, :unique => true
    end
  end
  def down
    change_Table :devices do |t|
      t.change :push_token, :string
    end
  end
end
