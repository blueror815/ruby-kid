class AddImageProcessingToItemPhotos < ActiveRecord::Migration
  def change
    add_column_unless_exists :item_photos, :image_processing, :boolean, null: false, default: false
  end
end
