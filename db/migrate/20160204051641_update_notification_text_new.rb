class UpdateNotificationTextNew < ActiveRecord::Migration
	def up

    	NotificationText.populate_from_yaml_file
  	end

  	def down
  	end
end
