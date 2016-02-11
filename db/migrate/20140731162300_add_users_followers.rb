class AddUsersFollowers < ActiveRecord::Migration
  def up
    create_table :followers_users do|t|
      t.integer :follower_user_id
      t.integer :user_id
    end
    add_index_unless_exists :followers_users, :user_id
    add_index_unless_exists :followers_users, [:follower_user_id, :user_id]
  end

  def down
  end
end
