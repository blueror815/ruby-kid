class RemoveUserEmailRequirement < ActiveRecord::Migration
  def up
    remove_index_if_exists :users, :email
    change_column :users, :email, :string, :length => 255, :null => true
    add_index :users, :email
  end

  def down
  end
end
