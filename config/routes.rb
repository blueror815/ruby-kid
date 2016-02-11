KidsToys::Application.routes.draw do



  use_doorkeeper

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  match 'admin' => 'users/admin#index', :via => :get, :as => 'admin'
  match 'admin' => 'users/admin#login', :via => :post, :as => 'admin_login'
  match 'admin/users' => 'users/admin#users', :via => :get, :as => 'admin_users'
  match 'admin/update_user/:id' => 'users/admin#update_user', :via => [:put, :post], :as => 'admin_update_user'
  match 'admin/delete_user/:id' => 'users/admin#delete_user', :via => [:delete], :as => 'admin_delete_user'
  match 'admin/schools' => 'users/admin#schools', :via => :get, :as => 'admin_schools'
  match 'admin/notifications' => 'users/admin#notifications', :via => :get, :as => 'admin_notifications'
  match 'admin/logout' => 'users/admin#logout', :via => [:get, :delete], :as => 'admin_logout'

  match 'question_answers/update_all' => 'question_answers#update_all', via: [:put, :post], as: 'update_all_question_answers'
  resources :question_answers, except:[:show]

  resources :item_comments

  resources :cart_items, module: 'carts'

  match 'schools/admin' => 'schools#admin', :via => :get, :as => :schools_admin
  match 'schools/admin/:id' => 'schools#admin_edit', :via => :get, :as =>  :schools_admin_edit
  match 'schools/admin/:id' => 'schools#admin_update', :via => :post, :as => :schools_admin_update
  match 'schools/admin/:id' => 'schools#admin_destroy', :via=> :delete, :as => :schools_admin_destroy
  resources :schools, path: '/schools'

  match '/demo' => 'items#demo'

  namespace :inventory do
    resources :manager, :only => [:index] do

    end
    match 'activate' => 'manager#activate', as: 'activate_item'
    match 'approve' => 'manager#approve', as: 'approve_item'
    match 'deactivate' => 'manager#deactivate', as: 'deactivate_item'
    match 'decline' => 'manager#decline', as: 'decline_item'

    match 'item_for_approval' => 'manager#item_for_approval_notice', as: 'item_for_approval_notice'
  end


  match 'admin/categories' => 'categories#admin', :as => :admin_categories
  match 'categories/update_all' => 'categories#update_all', as: :update_all_categories, via:[:put, :post]
  resources :categories

  match 'category_groups/update_all' => 'category_groups#update_all', as: :update_all_category_groups, via:[:put, :post]
  match 'category_groups/:id/add_mapping' => 'category_groups#add_mapping', as: :add_category_group_mapping, via:[:put, :post]
  match 'category_groups/:id/add_curated_category' => 'category_groups#add_curated_category', as: :add_curated_category, via:[:put, :post]
  resources :category_groups
  resources :category_group_mappings, only: [:edit, :update]

  match 'categories/:id(/:title)' => 'categories#show', :as => :category_title
  match 'user_categories' => 'categories#user_categories', :as => :user_categories

  get 'account/confirm' => 'account_confirmation#index', as: :account_confirmation
  get 'account/credit_card' => 'account_confirmation#credit_card', as: :account_credit_card
  get 'account/driver_license' => 'account_confirmation#driver_license', as: :account_driver_license
  post 'account/driver_license' => 'account_confirmation#upload_driver_license', as: :account_upload_driver_license
  post 'account/confirm/payment' => 'account_confirmation#authorize_payment', as: :account_confirmation_payment
  get 'account/confirmed' => 'account_confirmation#account_confirmed', as: :account_confirmed
  #####################
  # Trade

  resources :trades, module: 'trading', except: [:edit, :update, :create], as: 'trade'
  match 'trades/(:id)(.:format)' => 'trading/trades#create', as: 'create_trade', via: :post
  match 'trades/(:id)(.:format)' => 'trading/trades#reply', as: 'reply_trade', via: :put
  match 'trades/:id/comments(.:format)' => 'trading/trades#list_comments', as: 'trade_comments', via: :get
  match 'trades/:id/comments(.:format)' => 'trading/trades#comments', as: 'create_trade_comments', via: :post
  match 'trades/:id/accept(.:format)' => 'trading/trades#accept', as: 'accept_trade', via: :post
  match 'trades/:id/decline(.:format)' => 'trading/trades#decline', as: 'decline_trade', via: :delete
  match 'trades/:id/cancel(.:format)' => 'trading/trades#destroy', as: 'cancel_trade', via: [:put, :post, :delete]
  match 'trades/:id/pick_meeting(.:format)' => 'trading/trades#pick_meeting', as: 'pick_meeting', via: [:put, :post]
  match 'trades/:id/respond_to_meeting(.:format)' => 'trading/trades#respond_to_meeting', as: 'respond_to_meeting', via: [:put, :post]
  match 'trades/:id/confirm(.:format)' => 'trading/trades#confirm_completion', as: 'confirm_completion', via: [:put, :post]
  match 'trades/:id/pack(.:format)' => 'trading/trades#confirm_packed', as: 'confirm_packed', via: [:put, :post]
  match 'trades/:id/completed(.:format)' => 'trading/trades#completed', as: 'completed_change', via: [:put, :post]

  resources :buy_requests, module: 'trading', only: [:new, :create, :show]
  match 'buy_requests/(:id)/accept(.:format)' => 'trading/buy_requests#accept', as: 'accept_buy_request', via: [:put, :post]
  match 'buy_requests/(:id)/decline(.:format)' => 'trading/buy_requests#decline', as: 'decline_buy_request', via: [:put, :post]
  match 'buy_requests/(:id)/confirm(.:format)' => 'trading/buy_requests#confirm', as: 'confirm_buy_request', via: [:put, :post]
  match 'buy_requests/(:id)/sold(.:format)' => 'trading/buy_requests#sold', as: 'sold_buy_request', via: [:put, :post]
  match 'buy_requests/(:id)/not_sold(.:format)' => 'trading/buy_requests#not_sold', as: 'not_sold_buy_request', via: [:put, :post]

  #####################
  # Notifications

  resources :notifications, module: 'users', only: [:index, :show] do
    member do
      delete 'delete'
    end
  end
  match 'notifications/archive' => 'users/notifications#archive', as: 'archive_notifications', via: :put
  match '/notifications/push' => 'users/notifications#send_push_notification', as: 'send_push_notification', via: [:put, :post]
  match '/notifications_count(.:format)' => 'users/notifications#count', as: 'notifications_count', via: :get

  root :to => 'home#home'
  get "/home/:version" => "home#home"
  get "/terms" => "home#terms"
  get "/privacy" => "home#privacy"
  get "/privacy_and_terms" => "home#privacy_and_terms"
  get "/safety" => "home#safety"
  get "/about_us" => "home#about_us"
  get "/faq" => "home#faq"

  match 'tips/update_all' => 'tips#update_all', via: [:put, :post], as: 'update_all_tips'
  resources :tips, except: [:show]

  #####################
  # User

  devise_for :users, path_names: {sign_in: "login", sign_out: "logout"}, controllers: {registrations: 'users', sessions: 'sessions', passwords: 'passwords'}
  devise_scope :user do
    post '/forgot_password', to: 'passwords#create'
    get '/users/password/edit', to: 'password#edit'
    put '/users/password', to: 'passwords#update'
  end
  #post '/forgot_password' => 'devise/passwords#create'
  #get '/forgot_password'=> 'devise/passwords#edit'

  # Custom routes that still use :users scope
  devise_scope :user do
    get "/users/logout" => "sessions#destroy"
    get "/users/show_current_user", as: "show_current_user"
    get "/users/dashboard", to: "users#dashboard", as: "users_dashboard"
    get "/users/friends", to: "users#friends", as: "users_friends"
    get "/users/:id/items", to: "stores#show", as: "users_items"

    get "/users/children", to: "users/children#index", as: "users_children"
    get "/users/child", to: "users/children#new", as: "users_new_child"
    match '/users/child/:id/school' => 'users/children#school', as: 'child_school', via:[:get]
    match '/users/child/:id/update_school' => 'users/children#update_school', as: 'child_update_school', via:[:put, :post]
    get "/users/child/:id", to: "users/children#edit", as: "users_edit_child"
    post "/users/child/create", to: "users/children#create", as: "users_create_child"
    post '/users/student/create', to: 'users/children#create_student', as: 'users_create_student'
    post "/users/push_notifications", to: "users/user_notification_tokens#create", as: "create_user_notification_tokens"
    post "/users/child/login", to: "users/children#login", as: "users_login_child"
    put "/users/child/:id", to: "users/children#update", as: "users_update_child"
    post "/users/sign_in_as/:id", to: "sessions#sign_in_as", as: "sign_in_as"

    get "/users/:id", to: "users#show", as: "user"
    put "/users/login(.format)", to: "sessions#new"
    put "/users" => "users#update", as: "update_user"

    get '/boundaries', to: 'users/boundaries#index', as: 'boundaries'
    put '/boundaries', to: 'users/boundaries#update', as: 'update_boundaries'

    get  '/users/potential_friends' => 'users/friend_request#index', as: 'potential_friends'
    get '/friend_request/:id' => 'users/friend_request#show', as: 'friend_request'
    post '/friend_request' => 'users/friend_request#create', as: 'create_friend_request'
    match '/friend_request/:id/accept' => 'users/friend_request#accept', as: 'accept_friend_request', via:[:put, :post]
    match '/friend_request/:id/decline' => 'users/friend_request#deny_request', as: 'deny_friend_request', via:[:put, :post]

    # Users APIs
    scope path: '/api/v1' do
      get '/users/followings', to: 'users#followings', as: 'api_get_followings'
      get '/videos/value_prop' => 'sessions#video', via: [:get]
      match '/users/logout' => 'sessions#destroy', via: [:get, :put, :delete], as: 'api_users_logout'

      get  '/users/potential_friends' => 'users/friend_request#index', as: 'api_get_potential_friends'
      post '/users/friend_request' => 'users/friend_request#create', as: 'api_create_friend_request'
      get '/users/friend_request/:id' => 'users/friend_request#show', as: 'api_show_friend_request'
      post '/users/friend_request/:id/accept' => 'users/friend_request#accept', as: 'api_accept_friend_request'
      post '/users/friend_request/:id/decline' => 'users/friend_request#deny_request', as: 'api_deny_friend_request'

      get 'users/me', to: 'users#me', as: 'api_show_current_user'
      get 'users/show_current_user', to: 'users#me'
      get 'users/dashboard', to: 'users#dashboard', as: 'api_users_dashboard'
      get 'users/:user_id/friends',    to: 'users#friends', as: 'api_specific_user_friends'
      get 'users/friends',    to: 'users#friends', as: 'api_users_friends'

      get 'users/children', to: 'users/children#index', as: 'api_users_children'
      get 'users/child', to: 'users/children#new', as: 'api_users_new_child'
      get 'users/child/:id', to: 'users/children#edit', as: 'api_users_edit_child'
      post 'users/child/create', to: 'users/children#create', as: 'api_users_create_child'
      post 'users/push_notifications', to: 'users/user_notification_tokens#create', as: 'api_create_user_notification_tokens'
      post 'users/child/login', to: 'users/children#login', as: 'api_users_login_child'
      put 'users/child/:id', to: 'users/children#update', as: 'api_users_update_child'
      post 'users/sign_in_as/:id', to: 'sessions#sign_in_as', as: 'api_sign_in_as'

      post 'users/children',   to: 'users/children#create'
      put  'users',            to: 'users#update'
      put  'users/child/:id',  to: 'users/children#update'

      get 'users/:id', to: 'users#show', as: 'api_user'

      get '/children/:child_id/dashboard/items', to: 'users/children#dashboard_parent', as: 'api_parent_child_dashboard'

      post 'users/:id/business_cards', to: 'users#business_cards', as: 'api_business_cards'
      get '/users/welcome/posting_info', to: 'categories#welcome_kids', as: 'welcome_kids_category'
    end

    scope path: '/api/v2' do
      get  '/users/potential_friends' => 'users/friend_request#index', as: 'api2_get_potential_friends'
      post '/users/friend_request' => 'users/friend_request#create', as: 'api2_create_friend_request'
      get '/users/friend_request/:id' => 'users/friend_request#show', as: 'api2_show_friend_request'
      post '/users/friend_request/:id/accept' => 'users/friend_request#accept', as: 'api2_accept_friend_request'
      post '/users/friend_request/:id/decline' => 'users/friend_request#deny_request', as: 'api2_deny_friend_request'
    end
  end

  scope path: '/api/v1' do

    resources :schools, path: '/schools'

    # Items APIs
    resources :item_comments
    post 'items/:id/decline', to: 'trades#decline'
    post 'items/:id/end', to: 'trades#destroy'

    match 'items/:id/favorite' => 'items#toggle_favorite_item', via: [:put, :post], as: 'api_toggle_favorite_item'
    post 'items', to: 'items#create'
    put 'items/:id/activate', to: 'manager#activate'
    put 'items/:id/deactivate', to: 'manager#deactivate'
    put 'items/:id', to: 'items#update'
    get 'items/:id/likes', to: 'items#user_likes'

    # Browse Items API
    match 'items/newest' => 'items#newest', :as => :api_newest_items
    match 'items/near_by' => 'items#near_by', :as => :api_near_by_items
    match 'items/friends' => 'items#friends', :as => :api_friends_items
    match 'items/likes' => 'items#likes', :as => :api_likes_items
    match 'users/:user_id/items/favorites' => 'items#likes', :as => :api_specific_favorite_items
    match 'items/favorites' => 'items#likes', :as => :api_favorite_items
    match 'items/search' => 'items#search', :as => :api_items_search
    match 'items/category/:category_id' => 'items#index', :as => :api_items_search_category
    match 'items/search/:query(/in-:category_id)' => 'items#index', :as => :api_items_search_query

    get 'items/dashboard', to: 'inventory/manager#index'
    get 'items/:id', to: 'items#show'
    get 'users/:id/items', to: 'stores#show'

    # Notifications APIs
    get  'notifications',             to: 'users/notifications#index'
    get  'notifications/count',       to: 'users/notifications#count'
    post 'notifications/devices',     to: 'users/user_notification_tokens#create'
    put  'notifications/:id/archive', to: 'users/notifications#archive'

    # Categories APIs
    get 'categories', to: 'categories#index'

    # Trading APIs
    get 'trades/dashboard', to: 'trading/trades#index', as: 'api_trades'

    get  'trades/eligibility', to: 'trading/trades#show_eligibility', as: "api_show_eligibility"

    resources :trades, module: 'trading', except: [:edit, :update, :create]
    get 'trades/:trade_id/users/:id/items', to: 'stores#items_for_trade', as: 'api_items_for_trade'
    get 'trades/:id/comments', to: 'trading/trades#list_comments', as: 'api_trade_comments'

    post 'trades', to: 'trading/trades#create', as: 'api_create_trade'
    put  'trades/:id/reply', to: 'trading/trades#reply', as: 'api_reply_trade'
    post 'trades/:id/accept', to: 'trading/trades#accept', as: 'api_accept_trade'
    post 'trades/:id/cancel', to: 'trading/trades#destroy', as: 'api_cancel_trade'
    post 'trades/:id/comments', to: 'trading/trades#comments', as: 'api_create_trade_comments'
    post 'trades/:id/meeting_places', to: 'trading/trades#set_meeting_place', as: 'api_pick_meeting'
    post 'trades/:id/respond_to_meeting', to: 'trading/trades#respond_to_meeting', as: 'api_respond_to_meeting'
    post 'trades/:id/confirm', to: 'trading/trades#confirm_completion', as: 'api_confirm_completion'
    post 'trades/:id/pack', to: 'trading/trades#confirm_packed', as: 'api_confirm_packed'
    put  'trades/:id/completed_confirmation', to: 'trading/trades#trade_completed', as: 'api_trade_completed'
    put 'trades/:id/completed', to: 'trading/trades#completed', as: 'api_completed_change', via: [:put, :post]

    delete 'trades/:id/decline', to: 'trading/trades#decline', as: 'api_decline_trade'

    resources :buy_requests, module:'trading', only: [:new, :create, :show]
    match 'cart(.:format)' => 'trading/buy_requests#create', as: 'api_cart_post', via: :post
    match 'cart/(:id)(.:format)' => 'trading/buy_requests#show', as: 'api_cart_show', via: :get
    match 'cart/(:id)/accept(.:format)' => 'trading/buy_requests#accept', as: 'api_accept_buy_request', via: [:put, :post]
    match 'cart/(:id)/decline(.:format)' => 'trading/buy_requests#decline', as: 'api_decline_buy_request', via: [:put, :post]
    match 'cart/(:id)/confirm(.:format)' => 'trading/buy_requests#confirm', as: 'api_confirm_buy_request', via: [:put, :post]
    match 'cart/(:id)/sold(.:format)' => 'trading/buy_requests#sold', as: 'api_sold_buy_request', via: [:put, :post]
    match 'cart/(:id)/not_sold(.:format)' => 'trading/buy_requests#not_sold', as: 'api_not_sold_buy_request', via: [:put, :post]
    match 'cart/new_item(.:format)' => 'trading/buy_requests#create', as: 'api_new_item_parent', via: [:put, :post]

    ##
    match 'carts/:seller_id(.:format)' => 'carts/carts#show', :via => :get, as: 'api_cart'
    match 'carts/:item_id' => 'carts/carts#add', :via => :post, as: 'api_carts_add'
    match 'carts/:item_id' => 'carts/carts#delete', :via => :delete, as: 'api_carts_delete'
    match 'carts/:item_id' => 'carts/carts#update', :via => :put, as: 'api_carts_update'
    match 'carts(.:format)' => 'carts/carts#index', as: 'api_carts'

    # Stores

    match 'stores/follow/:id' => 'stores#follow', as: 'api_follow_user'
    match 'stores/is_following/:id(.:format)' => 'stores#is_following', :via => [:get, :put], as: 'api_is_following_user'
    match 'store_carts/:id(/:name)(.:format)' => 'stores#show_for_cart', :via => :get, as: 'api_store_cart'
    match 'stores/:id(/:name)(.:format)' => 'stores#show', :via => :get, as: 'api_store'
    match 'stores' => 'stores#index', :via => :get, as: 'api_stores'

    match 'zip_codes(.:format)' => 'geocode/zip_codes#index', as: 'api_zip_codes'

    # Users
    match 'boundaries(.format)' => 'users/boundaries#index', :via => :get, :as => 'api_boundaries'
    match 'boundaries(.format)' => 'users/boundaries#update', :via => :put, :as => 'api_update_boundaries'
  end

  # Items
  match 'items/newest' => 'items#newest', :as => 'newest_items'
  match 'items/near_by' => 'items#near_by', :as => 'near_by_items'
  match 'items/friends' => 'items#friends', :as => 'friends_items'
  match 'items/likes' => 'items#likes', :as => 'likes_items'
  match 'items/favorites' => 'items#likes', :as => 'favorite_items'
  match 'items/search' => 'items#search', :as => 'items_search'
  match 'items/category/:category_id' => 'items#index', :as => 'items_search_category'
  match 'items/search/:query(/in-:category_id)' => 'items#index', :as => 'items_search_query'

  resources :items

  #match 'items/:id/:title' => 'items#show', :as => :item_title, :via => [:get]
  match 'items/toggle_favorite_item/:id' => 'items#toggle_favorite_item', as: 'toggle_favorite_item'
  match 'items/:id/review' => 'items#review', as: 'review_item'

  # match 'items/:id/edit' => 'items#edit', :as => :edit_item # Originally done by resources :items, but next pattern with title creates conflict.

  resources :user_locations, module: 'users', except: [:edit]
  resources :user_phones, module: 'users', except: [:edit]

  resources :devices

  resources :permissions, module: 'users'

  # Reports
  match 'reports/:id/repost' => 'reports#repost', as: 'report_repost', via: [:post, :put]
  match 'reports/:id/approve' => 'reports#repost', as: 'report_approve', via: [:post, :put]
  resources :reports

  scope path: '/api/v1' do
    match 'reports/:id/repost' => 'reports#repost', as: 'api_report_repost', via: [:post, :put]
    match 'reports/:id/approve' => 'reports#repost', as: 'api_report_approve', via: [:post, :put]
    resources :reports
  end

  resources :fund_raisers
  get '/fundraising' => 'fund_raisers#new'

  ####################
  # Non-resources (model-based) routes

  match '(errors)/:status', to: 'errors#show', constraints: {status: /\d{3}/}, as: 'error'
  match '/log_into_app', to: 'errors#log_into_app', constraints: {status: /\d{3}/}, as: 'log_into_app'

  # Carts for holding interested items
  match 'carts/:seller_id(.:format)' => 'carts/carts#show', :via => :get, as: 'cart'
  match 'carts/:item_id' => 'carts/carts#add', :via => :post, as: 'carts_add'
  match 'carts/:item_id' => 'carts/carts#delete', :via => :delete, as: 'carts_delete'
  match 'carts/:item_id' => 'carts/carts#update', :via => :put, as: 'carts_update'
  match 'carts(.:format)' => 'carts/carts#index', as: 'carts'

  # Stores
  match 'stores/follow/:id' => 'stores#follow', as: 'follow_user'
  match 'stores/is_following/:id(.:format)' => 'stores#is_following', :via => [:get, :put], as: 'is_following_user'
  match 'store_carts/:id(/:name)(.:format)' => 'stores#show_for_cart', :via => :get, as: 'store_cart'
  get 'stores/:id/items_for_trade/:trade_id', to: 'stores#items_for_trade', as: 'store_items_for_trade'
  match 'stores/:id(/:name)(.:format)' => 'stores#show', :via => :get, as: 'store'
  match 'stores' => 'stores#index', :via => :get, as: 'stores'

  # Store Landing page like /greenviper
  match ':user_name' => 'stores#landing', as: 'store_landing'
  match 'forgot_password' => 'devise/passwords#create', :via => [:put, :post], as: 'forgot_password'
  match 'forgot_password'=> 'devise/passwords#edit', :via => [:get], as: 'password_reset'


  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
