class AddWaitingForUserId < ActiveRecord::Migration
  def up
    add_column_unless_exists :trades, :waiting_for_user_id, :integer
  end

  def down
  end
end
