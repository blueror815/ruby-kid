class AddCompletedConfirmedToTrades < ActiveRecord::Migration
  def change

    add_column_unless_exists :trades, :completion_confirmed, :boolean, default: false
    add_index_unless_exists :trades, :completion_confirmed
  end
end
