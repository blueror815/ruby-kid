class AddIconLabelToCategories < ActiveRecord::Migration
  def change
    add_column_unless_exists :categories, :icon_label, :string, length: 127
  end
end
