class AddCompletedTimeToTrades < ActiveRecord::Migration
  def up
  	add_column_unless_exists :trades, :completed_at, :datetime
  end

  def down
  	remove_column :trades, :completed_at, :datetime
  end
end
