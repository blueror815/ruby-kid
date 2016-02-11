class AddStatusToItemComment < ActiveRecord::Migration
  def change
    add_column_unless_exists :item_comments, :status, :string, default: 'OPEN', length:48
    add_index_unless_exists :item_comments, :status
  end
end
