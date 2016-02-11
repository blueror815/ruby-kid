class AddPublishedToLikes < ActiveRecord::Migration
  def up
    add_column_unless_exists :favorite_items, :published, :boolean, default: true
  end

  def down
    remove_column :favorite_items, :published
  end
end
