class MakeUserNotificationTokenUnique < ActiveRecord::Migration
  def up
    change_table :user_notification_tokens do |t|
      t.change :token, :string, :unique => true
    end
  end

  def down
    change_table :user_notification_tokens do |t|
      t.change :token, :string
    end
  end
end
