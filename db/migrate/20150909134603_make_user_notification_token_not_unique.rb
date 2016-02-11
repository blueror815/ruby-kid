class MakeUserNotificationTokenNotUnique < ActiveRecord::Migration
  def up
    change_table :user_notification_tokens do |t|
      t.change :token, :string, :unique => false
    end
  end

  def down
    change_table :user_notification_tokens do |t|
      t.change :token, :string, :unique => true
    end
  end
end
