class AddTotalItemsUser < ActiveRecord::Migration
  def up
    add_column_unless_exists :users, :item_total, :integer, default: 0
    add_column_unless_exists :users, :open_item_total, :integer, default: 0
  end

  def down
    remove_column :users, :item_total
    remove_column :users, :open_item_total
  end
end
