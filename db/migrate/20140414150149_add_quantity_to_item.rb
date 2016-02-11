class AddQuantityToItem < ActiveRecord::Migration
  def change
    add_column_unless_exists :items, :quantity, :integer, :default => 1
  end
end
