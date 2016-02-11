class AddOtherReasonToTrades < ActiveRecord::Migration
  def up
    add_column_unless_exists :trades, :other_reason, :string
  end

  def down
    remove_column :trades, :other_reason
  end
end
