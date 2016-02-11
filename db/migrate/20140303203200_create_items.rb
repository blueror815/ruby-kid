class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.integer :user_id
      t.string :title
      t.float :price
      t.text :description
      t.string :status

      t.timestamps
    end
    add_index_unless_exists :items, :user_id
    add_index_unless_exists :items, :status
    add_index_unless_exists :items, :created_at
    
    create_table :categories_items do |t|
      t.integer :item_id
      t.integer :category_id
    end
    add_index_unless_exists :categories_items, :item_id
  end
end
