class AddIndexToBuyRequestsCreatedAt < ActiveRecord::Migration
  def change

    add_index_unless_exists :buy_requests, :created_at
  end
end
