worker_processes 4
timeout 15
preload_app false

root_dir = "/var/www/cubby_shop"
shared_dir = "#{root_dir}/shared"
log_dir = "#{shared_dir}/log"

working_directory = "#{root_dir}/current"

pid "#{shared_dir}/tmp/pids/unicorn.pid"

stderr_path "#{log_dir}/unicorn.stderr.log"
stdout_path "#{log_dir}/unicorn.stdout.log"

listen "/tmp/unicorn.sock", :backlog => 64
listen 8080, :tcp_nopush => true

puts "Starting Unicorn"
puts "Log Directory: #{log_dir}"

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end