class CreateCategories < ActiveRecord::Migration
  def change
    create_table_unless_exists :categories do |t|
      t.string :name, :null => false
      t.integer :level, :default => 1
      t.integer :level_order, :default => 0
      t.integer :parent_category_id
      t.string :full_path_ids

    end
  end
end
