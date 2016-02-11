class CreateFilteredRecord < ActiveRecord::Migration
  def up
    create_table_unless_exists :filtered_records do|t|
      t.integer :user_id, null: false
      t.string  :content_type, null: false, length: 255
      t.integer :content_type_id, null: false
      t.string  :text_attribute, length: 255
      t.text    :original_text, null: false
      t.text    :matches, null: false
      t.integer :status_code, default: 0
      t.boolean :reviewed_by_parent, default: false
      t.boolean :reviewed_by_admin, default: false
      t.timestamps
    end
    add_index_unless_exists :filtered_records, :user_id
    add_index_unless_exists :filtered_records, [:content_type, :content_type_id]
    add_index_unless_exists :filtered_records, :status_code
    add_index_unless_exists :filtered_records, :created_at
  end

  def down
    drop_table_if_exists :filtered_records
  end
end
