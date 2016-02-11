class CreateNotificationMails < ActiveRecord::Migration
  def change
    create_table_unless_exists :notification_mails do |t|
      t.integer :sender_user_id, null: false
      t.integer :recipient_user_id, null: false
      t.text    :mail, null: false
      t.string  :status, default: 'DRAFT', length: 16
      t.timestamps
    end
    
    add_index_unless_exists :notification_mails, :status
  end
  
  
end
