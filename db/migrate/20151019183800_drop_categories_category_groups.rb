class DropCategoriesCategoryGroups < ActiveRecord::Migration
  def up
    drop_table_if_exists :categories_category_groups
    rename_column :curated_categories, :order, :order_index
  end

  def down
  end
end
