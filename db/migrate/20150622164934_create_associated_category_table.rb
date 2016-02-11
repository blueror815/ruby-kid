class CreateAssociatedCategoryTable < ActiveRecord::Migration
  def up
  	create_table_unless_exists 'associated_categories' do |t|
  		t.integer :category_id, null: false
  		t.integer :item_id, null: false
  	end
  end

  def down
  	drop_table_if_exists 'associated_categories'
  end
end
