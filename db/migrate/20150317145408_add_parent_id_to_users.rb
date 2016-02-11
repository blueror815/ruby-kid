class AddParentIdToUsers < ActiveRecord::Migration
  def change
    add_column_unless_exists :users, :parent_id, :integer, null: false
  end
end
