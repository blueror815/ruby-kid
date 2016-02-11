class AddPackedToTrades < ActiveRecord::Migration
  def change
    add_column_unless_exists :trades, :buyer_packed, :boolean, default: false
    add_column_unless_exists :trades, :seller_packed, :boolean, default: false
  end
end
