class AddFriendRequestTable < ActiveRecord::Migration
  def up
    create_table_unless_exists :friend_requests do |t|
      t.integer :requester_user_id, null: false
      t.integer :recipient_user_id, null: false
      t.string  :requester_message
      t.string  :recipient_message
      t.integer :status, default: 0
      t.integer :requester_parent_id
      t.integer :recipient_parent_id 
    end
  end

  def down
    drop_table_if_exists :friend_requests
  end
end
