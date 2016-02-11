class AddUserNotificationTokensTable < ActiveRecord::Migration
  def up
  	create_table_unless_exists 'user_notification_tokens' do |t|
  		t.integer :user_id, null: false
  		t.string :token
  		t.string :platform_type
  	end
  end

  def down
  	drop_table_if_exists 'user_notification_tokens'
  end
end

