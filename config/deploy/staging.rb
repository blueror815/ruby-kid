set :environment, "staging"
set :rails_env,   "staging"

role :web, "deploy@staging.cubbyshop.com"
role :app, "deploy@staging.cubbyshop.com"

set :ssh_options, {
  user: 'deploy',
  keys: [ "config/certificates/CubbyShop-Staging-deploy.pem"],
  forward_agent: true,
  auth_methods: %w(publickey)
 }