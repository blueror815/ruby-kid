class AddIndexToFollowUserId < ActiveRecord::Migration
  def change
    add_index_unless_exists :followers_users, :follower_user_id
  end
end
