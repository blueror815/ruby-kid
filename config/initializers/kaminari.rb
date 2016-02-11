# config/initializers/kaminari.rb

#this is to prevent conflicts between Active Admin and will_paginate

#source: http://activeadmin.info/docs/0-installation.html#setting-up-active-admin
Kaminari.configure do |config|
  config.page_method_name = :per_page_kaminari
end