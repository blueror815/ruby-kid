# config valid only for current version of Capistrano
lock '3.4.0'

set :stages, %w(production staging development)
set :default_stage, 'development'

set :application, 'cubby_shop'
set :repo_url, 'git@github.com:CubbyShopLLC/app_server.git'

base_path = '/var/www/cubby_shop'
current_path = base_path + '/current'
set :unicorn_config_path, File.join(current_path, 'config/unicorn.rb' )
set :unicorn_pid, File.join(current_path, 'tmp/pids/unicorn.pid' )

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name

set :deploy_to, base_path

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
set :pty, false
set :format, :pretty
set :log_level, :debug

set :sidekiq_log, File.join(base_path, 'current', 'log', 'sidekiq.log')
set :sidekiq_pid, File.join(base_path, 'current', 'tmp', 'sidekiq.pid')

set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system public/static_uploads}

set :keep_releases, 5

set :user, 'deploy'
set :use_sudo, false

set :assets_dependencies, %w(app/assets lib/assets vendor/assets Gemfile.lock config/routes.rb)

# Delayed job
set :delayed_job_bin_path, 'script'

namespace :deploy do

  desc "Run or restart Unicorn"
  task :run_unicorn do
    on roles(:app), in: :sequence do
      execute "echo \"Starting Unicorn for environment: #{fetch(:environment)}\""
      unicorn_pid = capture "cat /var/www/cubby_shop/shared/tmp/pids/unicorn.pid"
      if unicorn_pid.length > 0
        info "Stopping Unicorn (pid=#{unicorn_pid}) via SIGTERM."
        execute "kill -9 #{unicorn_pid}; true"
      else
        info "Unicorn was not running."
      end
      info "Starting Unicorn..."
      within current_path do
        execute :bundle, :exec, "unicorn_rails -c \"#{current_path}/config/unicorn.rb\" -E #{fetch(:environment)} -D"
      end
    end
  end

  desc "start sunspot server"
  task :restart_sunspot do
    on roles(:app), in: :sequence, wait: 5 do
      within current_path do
        execute :bundle, "exec", :rake, "sunspot:solr:start"
      end
    end
  end

  # From http://airbladesoftware.com/notes/deploying-and-monitoring-delayed-job-with-monit/

  # Override normal restart to force wait for job-in-progress to finish.
  # http://gist.github.com/178397
  # http://github.com/collectiveidea/delayed_job/issues#issue/3
  # desc "Restart the delayed_job process"
  # task :restart_dj do
  #   on roles(:app), in: :sequence, wait: 5 do
  #     within current_path do
  #       info "|_ restart_dj"
  #       execute :chmod, "+x #{current_path}/script/delayed_job"
  #       ##invoke 'delayed_job:restart'
  #     end
  #   end
  # end

  desc "Write a new crontab from the whenever gem"
  task :update_crontab do
    on roles(:app), in: :sequence, wait: 5 do
      within current_path do
        execute :bundle, "exec", "whenever", "-w"
      end
    end
  end
end


after "deploy", "deploy:run_unicorn"
after "deploy", "deploy:update_crontab"

require 'appsignal/capistrano'
