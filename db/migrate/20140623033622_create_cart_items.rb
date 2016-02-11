class CreateCartItems < ActiveRecord::Migration
  def change
    create_table_unless_exists :cart_items do |t|
      t.integer :item_id
      t.integer :user_id
      t.integer :seller_id
      t.integer :quantity

      t.timestamps
    end
    
    add_index_unless_exists :cart_items, [:item_id]
    add_index_unless_exists :cart_items, [:user_id]
    add_index_unless_exists :cart_items, [:user_id, :seller_id]
    add_index_unless_exists :cart_items, [:updated_at]
  end
end
