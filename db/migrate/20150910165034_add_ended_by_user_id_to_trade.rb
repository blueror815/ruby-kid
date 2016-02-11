class AddEndedByUserIdToTrade < ActiveRecord::Migration
  def up
    add_column_unless_exists :trades, :ended_by_user_id, :integer, :default => 0
  end

  def down
    remove_column :trades, :ended_by_user_id, :integer, :default => 0
  end
end
