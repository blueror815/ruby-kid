class AddNotifications < ActiveRecord::Migration
  def up
    create_table_unless_exists :notifications do|t|
      t.integer :sender_user_id, null: false
      t.integer :recipient_user_id, null: false
      t.string :title, length: 255
      t.string :uri, length: 511
      t.string :local_references_code, length: 511
      t.string :status, length: 24, default: 'WAIT'
      t.timestamps
    end
    
    add_index :notifications, :sender_user_id
    add_index :notifications, :recipient_user_id
    add_index :notifications, [:recipient_user_id, :status]
    add_index :notifications, :created_at
    
  end

  def down
    drop_table_if_exists :notifications
  end
end
