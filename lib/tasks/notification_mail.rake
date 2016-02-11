
task :deliver_notification_mails => :environment do
  puts "#############################"
  puts Time.now.to_s(:db)
  puts "Queue: #{NotificationMail.drafts.count}"
  NotificationMail.deliver_drafts
end

task :clean_up_expired_notifications => :environment do

  QUERY_CONDITION = "expires_at IS NOT NULL AND expires_at < NOW()"

  puts "#############################"
  puts "Clean Up Expired Notifications"
  puts Time.now.to_s(:db)
  puts "Queue: #{::Users::Notification.expired.count('id') }"
  update_count = ::Users::Notification.expired.update_all( { status: ::Users::Notification::Status::DELETED } )
  puts " .. expired #{update_count} notifications"

end