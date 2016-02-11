task :send_account_confirm_emails => :environment do
  puts "checking all users that aren't account confirmed, and sending them an email to confirm their account"
  NotificationMail.send_account_confirm_emails
  puts "done"
end
