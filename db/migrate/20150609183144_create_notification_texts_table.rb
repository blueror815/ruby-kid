class CreateNotificationTextsTable < ActiveRecord::Migration
  def up
  	create_table_unless_exists :notification_texts do |t|
  		t.string :identifier, :uniqueness => true
      t.string :non_tech_description
  		t.string :title
  		t.string :subtitle
  		t.string :push_notification
  		t.string :language
      t.timestamps
  	end
  end

  def down
  	drop_table :notification_texts
  end
end
