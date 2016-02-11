class AddTipToNotifications < ActiveRecord::Migration
  def change
    add_column_unless_exists :notifications, :tip, :string, length: 255
  end
end
