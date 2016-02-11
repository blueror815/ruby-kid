#this will call RPush to send all the push notifications in the rpush queue.
#right now, we only use Rpush for android push notificaitons

task :send_android_push_notifications => :environment do
  puts "sending pushing notifications for android"
  Rpush.push
  puts "done sending push notifications for android"
end
