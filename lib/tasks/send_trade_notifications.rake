
#rake task to check if a completed a trade from 4 days ago needs to send
# a message from CubbyShop to 

task :send_notification_for_completed_trades => :environment do
	puts "Pulling current completed trades and checking if they were completed four days ago."
	puts "if they were, sending them a push notification"
	::Trading::Trade.create_message_for_completed_trades
	puts"done"
end
