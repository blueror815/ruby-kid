class AddItemCountAndTradeCountToUser < ActiveRecord::Migration
  def change
    add_column_unless_exists :users, :item_count, :integer, default: 0
    add_column_unless_exists :users, :trade_count, :integer, default: 0
  end
end
