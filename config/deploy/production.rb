set :environment, 'production'
set :rails_env,   "production"

set :branch, "production"

role :web, "deploy@kidstrade.com"
role :app, "deploy@kidstrade.com"

set :ssh_options, {
    user: 'deploy',
    keys: [ "config/certificates/CubbyShop-Production-deploy.pem"],
    forward_agent: true,
    auth_methods: %w(publickey)
}

# The server-based syntax can be used to override options:
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
