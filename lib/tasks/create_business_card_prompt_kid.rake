task :create_business_card_prompt_kid => :environment do
  puts "Creating prompts for kids to print their business cards"
  User.create_business_card_prompt_kid
  puts "done creating kid message board noti"
end
