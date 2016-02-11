class CreateUserPhones < ActiveRecord::Migration
  def change
    create_table_unless_exists :user_phones do |t|
      t.integer :user_id, null: false
      t.string :number, null: false
      t.string :phone_type, default: 'HOME', length: 16
      t.boolean :is_primary, default: false

      t.timestamps
    end
    
    add_index_unless_exists :user_phones, :user_id
  end
end
