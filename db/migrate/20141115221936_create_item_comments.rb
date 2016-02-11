class CreateItemComments < ActiveRecord::Migration
  def up
      create_table_unless_exists :item_comments do|t|
        t.integer :user_id
        t.integer :recipient_user_id
        t.integer :buyer_id
        t.integer :item_id
        t.integer :parent_id
        t.string :body, length: 1027
        t.timestamps
      end
      add_index_unless_exists :item_comments, :item_id
      add_index_unless_exists :item_comments, :recipient_user_id
      add_index_unless_exists :item_comments, [:item_id, :buyer_id]
    end
  
    def down
      drop_table_if_exists :item_comments
    end
end
