class AddTradeModels < ActiveRecord::Migration
  def up

    create_table_unless_exists :trades do |t|
      t.integer :buyer_id, null: false
      t.integer :seller_id, null: false
      t.string  :status, null: false, default: 'OPEN', length: 56
      t.boolean :buyer_agree, default: false
      t.boolean :seller_agree, default: false
      t.timestamps
    end
    add_index_unless_exists :trades, :buyer_id
    add_index_unless_exists :trades, :seller_id

    create_table_unless_exists :trades_items do|t|
      t.integer :trade_id, null: false
      t.integer :item_id, null: false
      t.integer :seller_id, null: false
      t.integer :quantity, default: 1
    end
    add_index_unless_exists :trades_items, :trade_id
    add_index_unless_exists :trades_items, :item_id


    create_table_unless_exists :trade_comments do |t|
      t.integer :trade_id, null: false
      t.integer :item_id
      t.integer :user_id, null: false
      t.string  :comment
      t.float   :price
      t.string  :status, default: 'WAIT', length: 56

      t.timestamps
    end
    add_index_unless_exists :trade_comments, :trade_id
    add_index_unless_exists :trade_comments, :user_id

  end

  def down
    drop_table_if_exists :trades
    drop_table_if_exists :trades_items
    drop_table_if_exists :trade_comments
  end
end
