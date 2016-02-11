class CreateCategoryCuratedItem < ActiveRecord::Migration
  def up
    add_column_unless_exists :categories, :male_age_group, :string, default: ''
    add_column_unless_exists :categories, :female_age_group, :string, default: ''

    create_table_unless_exists :category_curated_items do|t|
      t.integer :category_id, null: false
      t.integer :item_id, null: false
    end
    add_index_unless_exists :category_curated_items, :category_id
  end

  def down
    remove_column_if_exists :categories, :male_age_group
    remove_column_if_exists :categories, :female_age_group
    drop_table_if_exists :category_curated_items
  end
end
