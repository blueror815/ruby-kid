class AddParentMessageToBuyRequest < ActiveRecord::Migration
  def change

    # Different message column than buyer's message column
    add_column_unless_exists :buy_requests, :parent_message, :text
  end
end
