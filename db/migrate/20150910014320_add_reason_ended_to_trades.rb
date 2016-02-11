class AddReasonEndedToTrades < ActiveRecord::Migration
  def up
    add_column_unless_exists :trades, :reason_ended, :integer, :default => 0
  end

  def down
    remove_column :trades, :reason_ended, :integer
  end
end
