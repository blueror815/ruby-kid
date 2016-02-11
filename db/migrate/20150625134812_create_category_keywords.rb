class CreateCategoryKeywords < ActiveRecord::Migration
  def up
  	create_table_unless_exists 'category_keywords' do |t|
  		t.integer :category_id, null: false
  		t.string :keyword, null: false
  	end
  end

  def down
  	drop_table_if_exists 'category_keywords'
  end
end
