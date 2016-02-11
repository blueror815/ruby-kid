class AddMainModelToNotification < ActiveRecord::Migration
  def change
    add_column_unless_exists :notifications, :related_model_type, :string, length: 48
    add_column_unless_exists :notifications, :related_model_id, :integer
    add_index :notifications, [:related_model_type, :related_model_id]
  end
end
