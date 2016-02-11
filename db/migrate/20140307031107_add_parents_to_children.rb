class AddParentsToChildren < ActiveRecord::Migration
  def change
    create_table :parents_children do|t|
      t.integer :parent_id
      t.integer :child_id
    end
    add_index_unless_exists :parents_children, :parent_id
    add_index_unless_exists :parents_children, :child_id
    
  end
end
