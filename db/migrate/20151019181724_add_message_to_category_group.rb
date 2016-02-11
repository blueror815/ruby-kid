class AddMessageToCategoryGroup < ActiveRecord::Migration
  def up
    add_column_unless_exists :category_groups, :message, :string
    add_column_unless_exists :curated_categories, :category_id, :integer
  end

  def down
    remove_column :category_groups, :message
    remove_column :curated_categories, :category_id
  end
end
