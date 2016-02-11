class AddIndicesToCategories < ActiveRecord::Migration
  def change
    
    add_index_unless_exists :categories, :parent_category_id
    add_index_unless_exists :categories, :level
  end
end
