class AddMoreToCategoryGroupMapping < ActiveRecord::Migration
  def change
    add_column_unless_exists :category_groups_categories, :order_index, :integer, default: 1
    add_column_unless_exists :category_groups_categories, :icon, :string, length: 255
    add_column_unless_exists :category_groups_categories, :icon_background_color, :string, length: 36
    add_column_unless_exists :category_groups_categories, :camera_background, :string, length: 255
  end
end
