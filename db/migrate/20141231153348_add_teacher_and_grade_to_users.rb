class AddTeacherAndGradeToUsers < ActiveRecord::Migration
  def change
    add_column_unless_exists :users, :teacher, :string
    add_column_unless_exists :users, :grade, :integer
  end
end
