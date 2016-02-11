class AddCreatedAtToFavoriteItems < ActiveRecord::Migration
  def change
    add_column_unless_exists :favorite_items, :created_at, :datetime
    add_index_unless_exists :favorite_items, :created_at
  end
end
