class AddDeniedItemsToTrades < ActiveRecord::Migration
  def change
    add_column :trades, :denied, :text
  end
end
