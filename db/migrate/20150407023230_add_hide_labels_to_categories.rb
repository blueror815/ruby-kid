class AddHideLabelsToCategories < ActiveRecord::Migration
  def change
    add_column_unless_exists :categories, :male_hides_name, :boolean, default: false
    add_column_unless_exists :categories, :female_hides_name, :boolean, default: false
  end
end
