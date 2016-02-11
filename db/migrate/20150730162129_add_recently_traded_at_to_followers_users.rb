class AddRecentlyTradedAtToFollowersUsers < ActiveRecord::Migration
  def change
    add_column_unless_exists :followers_users, :last_traded_at, :datetime
    add_index_unless_exists :followers_users, :last_traded_at
  end
end
