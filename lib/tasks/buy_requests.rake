

task :expire_not_sold_buy_requests => :environment do
  puts "#############################"
  puts "# Expire BuyRequests Not Sold for Too Long, now #{Time.now.to_s(:db)}"

  ::Trading::BuyRequest.expire_not_sold

end
