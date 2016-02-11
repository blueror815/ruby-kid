class AddMeetingFlagToTradeComment < ActiveRecord::Migration
  def up
    add_column_unless_exists :trade_comments, :is_meeting_place, :boolean, default: false
  end

  def down
    remove_column :trade_comments, :is_meeting_place
  end
end
