
##
# This reviews the still pending reports after 3-days and before 7-days of age, and make extensive user blocking.

task :review_pending_reports => :environment do
  puts "#############################"
  puts "# Review PENDING Reports to extend user blocks, now #{Time.now.to_s(:db)}"

  ::Report.review_pending_reports

end
