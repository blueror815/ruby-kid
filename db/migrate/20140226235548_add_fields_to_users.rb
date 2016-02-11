class AddFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :type, :string, :null => false, :limit => 64, :default => 'Parent'
    add_column :users, :user_name, :string, :null => false, :limit => 64
    add_column :users, :first_name, :string, :null => false, :limit => 64
    add_column :users, :last_name, :string, :limit => 64
    add_column :users, :interests, :text
    add_column :users, :birthdate, :date
    
    add_index_unless_exists :users, :type
    add_index_unless_exists :users, :user_name
  end
end
