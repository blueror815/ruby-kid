class AddParentTitleTip < ActiveRecord::Migration
  def up
    add_column_unless_exists :notification_texts, :title_for_parent, :string
    add_column_unless_exists :notification_texts, :tip_for_parent, :string
  end

  def down
    remove_column :notification_texts, :title_for_parent, :string
    remove_column :notification_texts, :tip_for_parent, :string
  end
end
