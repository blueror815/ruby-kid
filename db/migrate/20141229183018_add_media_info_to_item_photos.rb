class AddMediaInfoToItemPhotos < ActiveRecord::Migration
  def change
    add_column_unless_exists :item_photos, :width, :float 
    add_column_unless_exists :item_photos, :height, :float 
    add_column_unless_exists :item_photos, :metadata, :text
  end
end
