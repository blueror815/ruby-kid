class AddMaleFemaleIndex < ActiveRecord::Migration
  def up
    
    add_column_unless_exists :categories, :male_index, :integer, :default => 0
    add_index_unless_exists :categories, :male_index
    
    add_column_unless_exists :categories, :female_index, :integer, :default => 0
    add_index_unless_exists :categories, :female_index
  end

  def down
  end
end
