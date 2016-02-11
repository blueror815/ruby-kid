class AddFavoriteItems < ActiveRecord::Migration
  def up
    create_table :favorite_items do|t|
      t.integer :user_id
      t.integer :item_id
    end
    add_index_unless_exists :favorite_items, :user_id
    add_index_unless_exists :favorite_items, [:item_id, :user_id]
  end

  def down
  end
end
