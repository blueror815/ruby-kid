source 'http://rubygems.org'

gem 'bundler'
gem 'rails', '3.2.18'

gem 'appsignal'

gem 'braintree'
gem 'rpush'

# To use debugger
group :test do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'rspec-sidekiq'
  gem 'rspec-solr'
  gem 'spork'
  gem 'spork-testunit'
  gem 'factory_girl'
  gem 'factory_girl_rails', '~> 4.0'
  gem 'timecop'
  gem 'rspec_junit_formatter', '~> 0.2.2'
end

group :development, :test do
  gem 'ruby-debug19'
  # gem 'byebug'
  gem 'pry'

  gem 'webrat'
  gem 'nokogiri'
  gem 'mechanize'
  gem 'capistrano-sidekiq'
end

########################################
# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# Backend level
gem 'activeadmin'
gem 'mysql2'
gem 'thin'
gem 'unicorn', '~> 4.6.3'

# Search
gem 'progress_bar'
gem 'sunspot_rails'
gem 'sunspot_solr'
gem 'will_paginate', '~> 3.0'
gem 'obscenity'

# Geocode
gem 'browser'
gem 'maxminddb'
gem 'geocoder'
gem 'gmaps4rails'

# View level
gem 'haml', '~> 3.1.6'
gem 'sass', '~> 3.2.9'
gem 'sass-rails',   '~> 3.2.3'
gem 'bootstrap-sass', '~> 2.3.2.1'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass'
  gem 'sprockets'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# User related
gem 'devise'
gem 'doorkeeper'
gem "recaptcha", :require => "recaptcha/rails"
gem 'browser-timezone-rails', '~> 0.0.8'

# To use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.0.0'

gem 'houston'
gem 'grocer'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'
gem 'capistrano-rbenv'
gem 'capistrano-bundler'
gem 'capistrano-rails'
gem 'capistrano-rvm', github: 'capistrano/rvm'
gem 'capistrano3-unicorn'
gem 'capistrano3-delayed-job', '~> 1.0'

# Redis
gem 'redis'
gem 'redis-namespace'
gem 'redis-rails'
gem 'redis-rack-cache'
gem 'record-cache'

# Server tasks
# gem 'mini_magick', '3.7.0'

gem 'rmagick', '2.13.2', :require => 'RMagick'
gem 'carrierwave', '>= 0.5.3'
gem 'fog'
gem 'sidekiq', '~> 2.17.7'
gem 'sidekiq-unique-jobs'
gem 'carrierwave_direct'
gem 'carrierwave_backgrounder'
gem 'nested_form'

gem 'mail', "2.5.4"
gem 'aws-ses', require: 'aws/ses'
gem 'whenever', :require => false

# Debugging
#gem 'meta_where'
#gem 'exception_logger', "~> 0.0.3", :git => 'git://github.com/ryancheung/exception_logger.git'
gem 'exception_notification'
gem 'daemons'
gem 'delayed_job', '~> 4.0'
gem 'delayed_job_active_record'
