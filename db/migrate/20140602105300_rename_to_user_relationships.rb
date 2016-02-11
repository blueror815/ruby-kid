class RenameToUserRelationships < ActiveRecord::Migration
  def up
    rename_table :parents_children, :user_relationships
    rename_column :user_relationships, :parent_id, :primary_user_id
    rename_column :user_relationships, :child_id, :secondary_user_id
    add_column :user_relationships, :relationship_type, :string, :length => 63, :default => 'Father'
    add_index :user_relationships, :relationship_type
  end
  
  def down
    # remove_column :parents_children, :relationship_type
  end
  
end