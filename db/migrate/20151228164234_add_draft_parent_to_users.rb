class AddDraftParentToUsers < ActiveRecord::Migration
  def up
    add_column_unless_exists :users, :finished_registering, :boolean, default: false
    add_column_unless_exists :users, :is_parent_email, :boolean, default: true
  end

  def down
    remove_column_if_exists :users, :finished_registering
    remove_column_if_exists :users, :is_parent_email
  end
end
