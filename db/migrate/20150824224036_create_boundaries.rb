class CreateBoundaries < ActiveRecord::Migration
  def change
    drop_table_if_exists :user_blocks
    drop_table_if_exists :item_blocks

    create_table :boundaries do |t|
      t.string :type, default: 'Users::Boundary', length: 255, null: false
      t.integer :user_id, null: false
      t.integer :content_type_id
      t.string :content_keyword
      t.timestamps
    end
    
    add_index_unless_exists :boundaries, :type
    add_index_unless_exists :boundaries, [:type, :content_type_id]
    add_index_unless_exists :boundaries, :user_id
  end
end
