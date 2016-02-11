class AddParentApproveToTrades < ActiveRecord::Migration
  def change

    add_column_unless_exists :trades, :buyer_parent_approve, :boolean, default: false
    add_column_unless_exists :trades, :seller_parent_approve, :boolean, default: false
  end
end
