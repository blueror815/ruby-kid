class ChangeDefaultIsPrimary < ActiveRecord::Migration
  def up
    change_column_null :user_locations, :is_primary, true
  end

  def down
  end
end
