class AddUserCountToSchool < ActiveRecord::Migration
  def change
    add_column_unless_exists :schools, :user_count, :integer, default: 0
  end
end
