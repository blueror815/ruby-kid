class CreateCategoryGroupsCategories < ActiveRecord::Migration
  def up
    create_table_unless_exists :category_groups_categories do|t|
      t.integer :category_group_id, null: false
      t.integer :category_id, null: false
    end
    add_index_unless_exists :category_groups_categories, :category_group_id
    add_index_unless_exists :category_groups_categories, :category_id
  end

  def down
    drop_table_if_exists :category_groups_categories
  end
end
