class AddCreatedAtToNotificationTokenTable < ActiveRecord::Migration
  def change
    change_table(:user_notification_tokens) {|t| t.timestamps}
  end
end
