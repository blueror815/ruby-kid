class AddGenderInfoToCategories < ActiveRecord::Migration
  def change
    add_column_unless_exists :categories, :male_icon, :string
    add_column_unless_exists :categories, :female_icon, :string
    add_column_unless_exists :categories, :male_camera_background, :string
    add_column_unless_exists :categories, :female_camera_background, :string
  end
end
