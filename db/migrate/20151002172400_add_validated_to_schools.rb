class AddValidatedToSchools < ActiveRecord::Migration
  def up
    add_column_unless_exists :schools, :validated_admin, :boolean, default: false
    add_column_unless_exists :schools, :homeschool, :boolean, default: false
  end

  def down
    remove_column :schools, :validated_admin
    remove_column :schools, :homeschool
  end
end
