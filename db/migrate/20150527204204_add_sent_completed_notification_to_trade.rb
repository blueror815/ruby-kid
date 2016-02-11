class AddSentCompletedNotificationToTrade < ActiveRecord::Migration
  def up
  	add_column_unless_exists :trades, :sent_completed_notification, :boolean, :default => false
  end

  def down
  	remove_column :trades, :sent_completed_notification, :boolean
  end
end
