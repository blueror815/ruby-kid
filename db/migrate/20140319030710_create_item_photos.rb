class CreateItemPhotos < ActiveRecord::Migration
  def change
    create_table :item_photos do |t|
      t.integer :item_id
      t.string :name
      t.string :image
      t.boolean :default_photo, :default => false
      
      t.timestamps
    end
    add_index_unless_exists(:item_photos, :item_id)
    
  end
end
