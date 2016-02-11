class AddCuratedCategoryTable < ActiveRecord::Migration
  def up
    create_table_unless_exists :curated_categories do |t|
      t.integer :order, default: 0
      t.integer :category_group_id
    end

    add_column_unless_exists :category_curated_items, :curated_category_id, :integer
  end

  def down
    drop_table_if_exists :curated_categories
    remove_column :category_curated_items, :curated_category_id
  end
end
