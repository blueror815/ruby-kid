class AddTrialCountToNotificationMail < ActiveRecord::Migration
  def up
    add_column_unless_exists :notification_mails, :trial_count, :integer, default: 0
  end
  
  def down
    remove_column_if_exists :notification_mails, :trial_count
  end
end
