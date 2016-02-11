class AddTypeAndExpireAtToNotifications < ActiveRecord::Migration
  def change
    add_column_unless_exists :notifications, :type, :string, length: 80, null: false, defaut: 'Users::Notifications::Basic'
    add_column_unless_exists :notifications, :expires_at, :datetime
    add_index_unless_exists :notifications, :expires_at
  end
end
