class AddUsersSchools < ActiveRecord::Migration
  def up
    create_table_unless_exists(:schools_users) do|t|
      t.integer :user_id, :null => false
      t.integer :school_id, :null => false
    end
    add_index_unless_exists :schools_users, :user_id
    add_index_unless_exists :schools_users, :school_id
  end

  def down
    drop_table_if_exists :schools_users
  end
end
