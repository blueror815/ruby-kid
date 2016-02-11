class CreateItemKeywords < ActiveRecord::Migration
  def change
    create_table :item_keywords do |t|
      t.integer :item_id
      t.string :keyword
      
    end
    add_index_unless_exists :item_keywords, :item_id
  end
end
