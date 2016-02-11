class AddPhotoUrlToItemPhoto < ActiveRecord::Migration
  def change
    add_column_unless_exists :item_photos, :url, :string, length: 191
  end
end
