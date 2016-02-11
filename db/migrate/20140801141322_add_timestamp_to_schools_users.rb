class AddTimestampToSchoolsUsers < ActiveRecord::Migration
  def change
    
    add_column_unless_exists :schools_users, :created_at, :datetime
    add_index_unless_exists :schools_users, :grade
    
  end
end
