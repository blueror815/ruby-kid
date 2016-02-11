class AddIndexToNotificationMails < ActiveRecord::Migration
  def change
    add_index_unless_exists :notification_mails, :created_at
  end
end
