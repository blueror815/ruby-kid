class AddPermissions < ActiveRecord::Migration
  def up
    
    create_table_unless_exists :permissions do|t|
      t.integer :user_id, null: false
      t.integer :secondary_user_id, null: false
      t.string :object_type, length: 55
      t.string :object_id, length: 55
    end
    add_index_unless_exists :permissions, :user_id
    add_index_unless_exists :permissions, :secondary_user_id
    add_index_unless_exists :permissions, [:user_id, :secondary_user_id]
    add_index_unless_exists :permissions, [:object_type, :object_id]
  end

  def down
    drop_table_if_exists :permissions
  end
end
