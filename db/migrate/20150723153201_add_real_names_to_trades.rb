class AddRealNamesToTrades < ActiveRecord::Migration
  def change
    add_column_unless_exists :trades, :buyer_real_name, :string, length: 127
    add_column_unless_exists :trades, :seller_real_name, :string, length: 127
  end


end
