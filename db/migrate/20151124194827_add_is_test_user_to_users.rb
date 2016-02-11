class AddIsTestUserToUsers < ActiveRecord::Migration
  def change
    add_column_unless_exists :users, :is_test_user, :boolean, default: false
    add_index_unless_exists :users, :is_test_user
  end
end
