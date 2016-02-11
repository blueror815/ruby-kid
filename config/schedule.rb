# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every 5.minutes do
  rake "deliver_notification_mails"
  rake "send_android_push_notifications"
  rake "notify_to_check_items"
end

#every 5.minutes do
#  rake "auto_approve_items"
#end


##
# This reviews the still pending reports in a period.
every 12.hours do
  rake "review_pending_reports"
end


# this is run to check for dates that are four days or greater than the current date
# and then
every 1.hour do
	rake "send_notification_for_completed_trades"
end

every 1.hour do
  rake "clean_up_expired_notifications"
end

# Check if buy requests have not completed with Sold status after a week
every 1.hour do
  rake "expire_not_sold_buy_requests"
end

every 1.hour do
  rake "send_account_confirm_emails"
end

every 1.day do
  rake "create_business_card_prompt_kid"
end
