class AddMailTypeAndTypeId < ActiveRecord::Migration
  def up
    add_column_unless_exists :notification_mails, :related_type, :string, length: 127
    add_column_unless_exists :notification_mails, :related_type_id, :integer
  end

  def down
  end
end
