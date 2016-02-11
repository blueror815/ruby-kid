class AddFriendRequestBoolean < ActiveRecord::Migration
  def up
    add_column_unless_exists :followers_users, :friend_request, :boolean, default: false
  end

  def down
    remove_column :followers_users, :friend_request
  end
end
