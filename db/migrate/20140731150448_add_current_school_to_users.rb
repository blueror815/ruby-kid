class AddCurrentSchoolToUsers < ActiveRecord::Migration
  def change
    
    add_column_unless_exists :users, :current_school_id, :integer
    
    add_column_unless_exists :schools_users, :teacher, :string, :length => 55
    add_column_unless_exists :schools_users, :grade, :integer
  end
end
