class AddUniqueIndexTimestableToFriendRequest < ActiveRecord::Migration
  def up
    add_index_unless_exists(:friend_requests, [:requester_user_id, :recipient_user_id], unique: true)
    add_column_unless_exists(:friend_requests, :created_at, :datetime)
    add_column_unless_exists(:friend_requests, :updated_at, :datetime)
  end

  def down
    remove_index_if_exists :friend_requests, column: [:requester_user_id, :recipient_user_id]
    remove_colunm_if_exists :friend_requests, :created_at
    remove_colunm_if_exists :friend_requests, :updated_at
  end
end
