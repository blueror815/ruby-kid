class CreateBuyRequests < ActiveRecord::Migration
  def up
    create_table_unless_exists :buy_requests do |t|
      t.integer :buyer_id, null: false
      t.integer :seller_id, null: false
      t.string :status, null: false, default: 'PENDING'
      t.text :message
      t.string :name
      t.string :email
      t.string :phone
      t.timestamps
    end
    add_index_unless_exists :buy_requests, :buyer_id
    add_index_unless_exists :buy_requests, :status

    create_table_unless_exists :buy_requests_items do|t|
      t.integer :buy_request_id
      t.integer :item_id
    end
    add_index_unless_exists :buy_requests_items,:buy_request_id
    add_index_unless_exists :buy_requests_items,:item_id
    
    ::NotificationText.populate_from_yaml_file

  end

  def down
    drop_table_if_exists :buy_requests
    drop_table_if_exists :buy_requests_items
  end
end
