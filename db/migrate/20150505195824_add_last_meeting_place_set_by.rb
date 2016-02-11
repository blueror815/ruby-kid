class AddLastMeetingPlaceSetBy < ActiveRecord::Migration
  def up
    
    add_column_unless_exists :trades, :last_meeting_place_set_by, :integer, default: 0
  end

  def down
  end
end
