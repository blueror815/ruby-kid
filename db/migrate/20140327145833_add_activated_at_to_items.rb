class AddActivatedAtToItems < ActiveRecord::Migration
  def up
    add_column_unless_exists :items, :activated_at, :datetime
  end

  def down
    remove_column_if_exists :items, :activated_at
  end
end
