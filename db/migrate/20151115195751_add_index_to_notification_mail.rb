class AddIndexToNotificationMail < ActiveRecord::Migration
  def change
    add_index_unless_exists :notification_mails, :recipient_user_id
    add_index_unless_exists :notification_mails, [:related_type, :related_type_id]
  end
end
