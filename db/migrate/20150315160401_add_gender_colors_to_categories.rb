class AddGenderColorsToCategories < ActiveRecord::Migration
  def change
    add_column_unless_exists :categories, :male_icon_background_color, :string, length: 55
    add_column_unless_exists :categories, :female_icon_background_color, :string, length: 55
  end
end
