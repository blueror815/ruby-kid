# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20160204051641) do

  create_table "active_admin_comments", :force => true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_active_admin_comments_on_resource_type_and_resource_id"

  create_table "admin_users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0,  :null => false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true

  create_table "all_categories", :force => true do |t|
    t.string   "name",               :limit => 255,                :null => false
    t.integer  "level",                             :default => 1
    t.integer  "level_order",                       :default => 0
    t.integer  "parent_category_id"
    t.string   "full_path_ids",      :limit => 255
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
  end

  add_index "all_categories", ["level"], :name => "index_categories_on_level"
  add_index "all_categories", ["parent_category_id"], :name => "index_categories_on_parent_category_id"

  create_table "associated_categories", :force => true do |t|
    t.integer "category_id", :null => false
    t.integer "item_id",     :null => false
  end

  create_table "boundaries", :force => true do |t|
    t.string   "type",            :default => "Users::Boundary", :null => false
    t.integer  "user_id",                                        :null => false
    t.integer  "content_type_id"
    t.string   "content_keyword"
    t.datetime "created_at",                                     :null => false
    t.datetime "updated_at",                                     :null => false
  end

  add_index "boundaries", ["type", "content_type_id"], :name => "index_boundaries_on_type_and_content_type_id"
  add_index "boundaries", ["type"], :name => "index_boundaries_on_type"
  add_index "boundaries", ["user_id"], :name => "index_boundaries_on_user_id"

  create_table "buy_requests", :force => true do |t|
    t.integer  "buyer_id",                              :null => false
    t.integer  "seller_id",                             :null => false
    t.string   "status",         :default => "PENDING", :null => false
    t.text     "message"
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.text     "parent_message"
  end

  add_index "buy_requests", ["buyer_id"], :name => "index_buy_requests_on_buyer_id"
  add_index "buy_requests", ["created_at"], :name => "index_buy_requests_on_created_at"
  add_index "buy_requests", ["status"], :name => "index_buy_requests_on_status"

  create_table "buy_requests_items", :force => true do |t|
    t.integer "buy_request_id"
    t.integer "item_id"
  end

  add_index "buy_requests_items", ["buy_request_id"], :name => "index_buy_requests_items_on_buy_request_id"
  add_index "buy_requests_items", ["item_id"], :name => "index_buy_requests_items_on_item_id"

  create_table "cart_items", :force => true do |t|
    t.integer  "item_id"
    t.integer  "user_id"
    t.integer  "seller_id"
    t.integer  "quantity"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "cart_items", ["item_id"], :name => "index_cart_items_on_item_id"
  add_index "cart_items", ["updated_at"], :name => "index_cart_items_on_updated_at"
  add_index "cart_items", ["user_id", "seller_id"], :name => "index_cart_items_on_user_id_and_seller_id"
  add_index "cart_items", ["user_id"], :name => "index_cart_items_on_user_id"

  create_table "categories", :force => true do |t|
    t.string   "name",                         :limit => 255,                      :null => false
    t.integer  "level",                                       :default => 1
    t.integer  "level_order",                                 :default => 0
    t.integer  "parent_category_id"
    t.string   "full_path_ids",                :limit => 255
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.integer  "male_index",                                  :default => 1234567
    t.integer  "female_index",                                :default => 1234567
    t.string   "male_icon",                    :limit => 255
    t.string   "female_icon",                  :limit => 255
    t.string   "male_camera_background",       :limit => 255
    t.string   "female_camera_background",     :limit => 255
    t.string   "male_icon_background_color",   :limit => 255
    t.string   "female_icon_background_color", :limit => 255
    t.string   "icon_label",                   :limit => 255
    t.boolean  "male_hides_name",                             :default => false
    t.boolean  "female_hides_name",                           :default => false
    t.string   "male_age_group",                              :default => ""
    t.string   "female_age_group",                            :default => ""
  end

  add_index "categories", ["female_index"], :name => "index_categories_on_female_index"
  add_index "categories", ["level"], :name => "index_categories_on_level"
  add_index "categories", ["male_index"], :name => "index_categories_on_male_index"
  add_index "categories", ["parent_category_id"], :name => "index_categories_on_parent_category_id"

  create_table "categories_items", :force => true do |t|
    t.integer "item_id"
    t.integer "category_id"
  end

  add_index "categories_items", ["item_id"], :name => "index_categories_postings_on_posting_id"

  create_table "category_curated_items", :force => true do |t|
    t.integer "category_id",         :null => false
    t.integer "item_id",             :null => false
    t.integer "curated_category_id"
  end

  add_index "category_curated_items", ["category_id"], :name => "index_category_curated_items_on_category_id"

  create_table "category_groups", :force => true do |t|
    t.string  "name",        :default => "",  :null => false
    t.string  "gender",      :default => ""
    t.integer "lowest_age",  :default => 0
    t.integer "highest_age", :default => 100
    t.string  "country"
    t.string  "message"
  end

  add_index "category_groups", ["country"], :name => "index_category_groups_on_country"
  add_index "category_groups", ["gender"], :name => "index_category_groups_on_gender"
  add_index "category_groups", ["lowest_age", "highest_age"], :name => "index_category_groups_on_lowest_age_and_highest_age"

  create_table "category_groups_categories", :force => true do |t|
    t.integer "category_group_id",                    :null => false
    t.integer "category_id",                          :null => false
    t.integer "order_index",           :default => 1
    t.string  "icon"
    t.string  "icon_background_color"
    t.string  "camera_background"
  end

  add_index "category_groups_categories", ["category_group_id"], :name => "index_category_groups_categories_on_category_group_id"
  add_index "category_groups_categories", ["category_id"], :name => "index_category_groups_categories_on_category_id"

  create_table "category_keywords", :force => true do |t|
    t.integer "category_id", :null => false
    t.string  "keyword",     :null => false
  end

  create_table "countries", :primary_key => "iso", :force => true do |t|
    t.string  "name",           :limit => 80, :null => false
    t.string  "printable_name", :limit => 80, :null => false
    t.string  "iso3",           :limit => 3
    t.integer "numcode",        :limit => 2
  end

  create_table "country_states", :id => false, :force => true do |t|
    t.string "country_iso", :limit => 2,  :default => "US"
    t.string "code",        :limit => 2,                    :null => false
    t.string "name",        :limit => 50,                   :null => false
  end

  add_index "country_states", ["code"], :name => "idx_code"
  add_index "country_states", ["country_iso", "code"], :name => "country_iso_code"

  create_table "curated_categories", :force => true do |t|
    t.integer "order_index",       :default => 0
    t.integer "category_group_id"
    t.integer "category_id"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",                         :default => 0, :null => false
    t.integer  "attempts",                         :default => 0, :null => false
    t.text     "handler",    :limit => 2147483647,                :null => false
    t.text     "last_error", :limit => 2147483647
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  :limit => 255
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"
  add_index "delayed_jobs", ["queue"], :name => "index_delayed_jobs_on_queue"

  create_table "devices", :force => true do |t|
    t.string   "type",       :limit => 255, :default => "Devices::Ios", :null => false
    t.integer  "user_id",                                               :null => false
    t.string   "push_token"
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
  end

  add_index "devices", ["user_id"], :name => "index_devices_on_user_id"

  create_table "favorite_items", :force => true do |t|
    t.integer  "user_id"
    t.integer  "item_id"
    t.datetime "created_at"
    t.boolean  "published",  :default => true
  end

  add_index "favorite_items", ["created_at"], :name => "index_favorite_items_on_created_at"
  add_index "favorite_items", ["item_id", "user_id"], :name => "index_favorite_items_on_item_id_and_user_id"
  add_index "favorite_items", ["user_id"], :name => "index_favorite_items_on_user_id"

  create_table "filtered_records", :force => true do |t|
    t.integer  "user_id",                               :null => false
    t.string   "content_type",                          :null => false
    t.integer  "content_type_id",                       :null => false
    t.string   "text_attribute"
    t.text     "original_text",                         :null => false
    t.text     "matches",                               :null => false
    t.integer  "status_code",        :default => 0
    t.boolean  "reviewed_by_parent", :default => false
    t.boolean  "reviewed_by_admin",  :default => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  add_index "filtered_records", ["content_type", "content_type_id"], :name => "index_filtered_records_on_content_type_and_content_type_id"
  add_index "filtered_records", ["created_at"], :name => "index_filtered_records_on_created_at"
  add_index "filtered_records", ["status_code"], :name => "index_filtered_records_on_status_code"
  add_index "filtered_records", ["user_id"], :name => "index_filtered_records_on_user_id"

  create_table "followers_users", :force => true do |t|
    t.integer  "follower_user_id"
    t.integer  "user_id"
    t.datetime "last_traded_at"
    t.boolean  "friend_request",   :default => false
  end

  add_index "followers_users", ["follower_user_id", "user_id"], :name => "index_followers_users_on_follower_user_id_and_user_id"
  add_index "followers_users", ["follower_user_id"], :name => "index_followers_users_on_follower_user_id"
  add_index "followers_users", ["last_traded_at"], :name => "index_followers_users_on_last_traded_at"
  add_index "followers_users", ["user_id"], :name => "index_followers_users_on_user_id"

  create_table "friend_requests", :force => true do |t|
    t.integer  "requester_user_id",                  :null => false
    t.integer  "recipient_user_id",                  :null => false
    t.string   "requester_message"
    t.string   "recipient_message"
    t.integer  "status",              :default => 0
    t.integer  "requester_parent_id"
    t.integer  "recipient_parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "friend_requests", ["requester_user_id", "recipient_user_id"], :name => "index_friend_requests_on_requester_user_id_and_recipient_user_id", :unique => true

  create_table "fund_raisers", :force => true do |t|
    t.string   "name",        :null => false
    t.string   "email"
    t.string   "school_name"
    t.string   "city_state"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "item_comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "recipient_user_id"
    t.integer  "buyer_id"
    t.integer  "item_id"
    t.integer  "parent_id"
    t.string   "body",              :limit => 255
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.string   "status",                           :default => "OPEN"
  end

  add_index "item_comments", ["item_id", "buyer_id"], :name => "index_item_comments_on_item_id_and_buyer_id"
  add_index "item_comments", ["item_id"], :name => "index_item_comments_on_item_id"
  add_index "item_comments", ["recipient_user_id"], :name => "index_item_comments_on_recipient_user_id"
  add_index "item_comments", ["status"], :name => "index_item_comments_on_status"

  create_table "item_keywords", :force => true do |t|
    t.integer "item_id"
    t.string  "keyword", :limit => 255
  end

  add_index "item_keywords", ["item_id"], :name => "index_item_keywords_on_item_id"

  create_table "item_photos", :force => true do |t|
    t.integer  "item_id"
    t.string   "name",             :limit => 255
    t.string   "image",            :limit => 255
    t.boolean  "default_photo",                          :default => false
    t.datetime "created_at",                                                :null => false
    t.datetime "updated_at",                                                :null => false
    t.float    "width"
    t.float    "height"
    t.text     "metadata",         :limit => 2147483647
    t.boolean  "image_processing",                       :default => false, :null => false
    t.string   "url",              :limit => 255
  end

  add_index "item_photos", ["item_id"], :name => "index_item_photos_on_item_id"

  create_table "items", :force => true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.float    "price"
    t.text     "description",           :limit => 2147483647
    t.string   "status"
    t.datetime "created_at",                                                      :null => false
    t.datetime "updated_at",                                                      :null => false
    t.datetime "activated_at"
    t.integer  "quantity",                                    :default => 1
    t.string   "default_thumbnail_url"
    t.integer  "view_count",                                  :default => 0
    t.string   "age_group",             :limit => 55
    t.string   "gender_group",          :limit => 255
    t.string   "intended_age_group",    :limit => 255,        :default => "same"
  end

  add_index "items", ["created_at"], :name => "index_postings_on_created_at"
  add_index "items", ["status"], :name => "index_postings_on_status"
  add_index "items", ["user_id"], :name => "index_postings_on_user_id"

  create_table "notification_mails", :force => true do |t|
    t.integer  "sender_user_id",                                         :null => false
    t.integer  "recipient_user_id",                                      :null => false
    t.text     "mail",              :limit => 2147483647,                :null => false
    t.string   "status",            :limit => 55
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
    t.integer  "trial_count",                             :default => 0
    t.string   "related_type"
    t.integer  "related_type_id"
  end

  add_index "notification_mails", ["created_at"], :name => "index_notification_mails_on_created_at"
  add_index "notification_mails", ["recipient_user_id"], :name => "index_notification_mails_on_recipient_user_id"
  add_index "notification_mails", ["related_type", "related_type_id"], :name => "index_notification_mails_on_related_type_and_related_type_id"
  add_index "notification_mails", ["status"], :name => "index_notification_mails_on_status"

  create_table "notification_texts", :force => true do |t|
    t.string   "identifier"
    t.string   "non_tech_description"
    t.string   "title"
    t.string   "subtitle"
    t.text     "push_notification"
    t.string   "language"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.string   "title_for_item"
    t.string   "subtitle_for_item"
    t.string   "title_for_trade"
    t.string   "subtitle_for_trade"
    t.string   "title_for_parent"
    t.string   "tip_for_parent"
    t.string   "title_for_trade_b"
    t.string   "tip_for_trade_b"
    t.string   "title_for_item_b"
    t.string   "tip_for_item_b"
  end

  add_index "notification_texts", ["identifier"], :name => "index_notification_texts_on_identifier"

  create_table "notifications", :force => true do |t|
    t.integer  "sender_user_id",                       :null => false
    t.integer  "recipient_user_id",                    :null => false
    t.string   "title"
    t.string   "uri"
    t.string   "local_references_code"
    t.string   "status",                :limit => 55
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.string   "related_model_type",    :limit => 127
    t.integer  "related_model_id"
    t.string   "tip"
    t.string   "type",                  :limit => 255, :null => false
    t.datetime "expires_at"
  end

  add_index "notifications", ["created_at"], :name => "index_notifications_on_created_at"
  add_index "notifications", ["expires_at"], :name => "index_notifications_on_expires_at"
  add_index "notifications", ["recipient_user_id", "status"], :name => "index_notifications_on_recipient_user_id_and_status"
  add_index "notifications", ["recipient_user_id"], :name => "index_notifications_on_recipient_user_id"
  add_index "notifications", ["related_model_type", "related_model_id"], :name => "index_notifications_on_related_model_type_and_related_model_id"
  add_index "notifications", ["related_model_type"], :name => "index_notifications_on_related_model_type"
  add_index "notifications", ["sender_user_id"], :name => "index_notifications_on_sender_user_id"

  create_table "oauth_access_grants", :force => true do |t|
    t.integer  "resource_owner_id", :null => false
    t.integer  "application_id",    :null => false
    t.string   "token",             :null => false
    t.integer  "expires_in",        :null => false
    t.text     "redirect_uri",      :null => false
    t.datetime "created_at",        :null => false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  add_index "oauth_access_grants", ["token"], :name => "index_oauth_access_grants_on_token", :unique => true

  create_table "oauth_access_tokens", :force => true do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id"
    t.string   "token",             :null => false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        :null => false
    t.string   "scopes"
  end

  add_index "oauth_access_tokens", ["refresh_token"], :name => "index_oauth_access_tokens_on_refresh_token", :unique => true
  add_index "oauth_access_tokens", ["resource_owner_id"], :name => "index_oauth_access_tokens_on_resource_owner_id"
  add_index "oauth_access_tokens", ["token"], :name => "index_oauth_access_tokens_on_token", :unique => true

  create_table "oauth_applications", :force => true do |t|
    t.string   "name",                         :null => false
    t.string   "uid",                          :null => false
    t.string   "secret",                       :null => false
    t.text     "redirect_uri",                 :null => false
    t.string   "scopes",       :default => "", :null => false
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "oauth_applications", ["uid"], :name => "index_oauth_applications_on_uid", :unique => true

  create_table "permissions", :force => true do |t|
    t.integer "user_id",                          :null => false
    t.integer "secondary_user_id",                :null => false
    t.string  "object_type",       :limit => 127
    t.string  "object_id"
  end

  add_index "permissions", ["object_type", "object_id"], :name => "index_permissions_on_object_type_and_object_id"
  add_index "permissions", ["secondary_user_id"], :name => "index_permissions_on_secondary_user_id"
  add_index "permissions", ["user_id", "secondary_user_id"], :name => "index_permissions_on_user_id_and_secondary_user_id"
  add_index "permissions", ["user_id"], :name => "index_permissions_on_user_id"

  create_table "question_answers", :force => true do |t|
    t.text     "question",                           :null => false
    t.text     "answer"
    t.integer  "created_by_user_id"
    t.integer  "answered_by_user_id"
    t.integer  "order_index",         :default => 0
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  create_table "reports", :force => true do |t|
    t.integer  "offender_user_id",                             :null => false
    t.integer  "reporter_user_id",                             :null => false
    t.integer  "resolver_user_id"
    t.string   "content_type",                                 :null => false
    t.integer  "content_type_id",                              :null => false
    t.string   "reason_type"
    t.text     "reason_message"
    t.string   "status"
    t.integer  "secondary_filter_severity"
    t.boolean  "resolved",                  :default => false
    t.integer  "resolution_level"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.time     "resolved_at"
  end

  add_index "reports", ["content_type", "content_type_id"], :name => "index_reports_on_content_type_and_content_type_id"
  add_index "reports", ["offender_user_id"], :name => "index_reports_on_offender_user_id"
  add_index "reports", ["reporter_user_id"], :name => "index_reports_on_reporter_user_id"
  add_index "reports", ["resolved"], :name => "index_reports_on_resolved"
  add_index "reports", ["resolver_user_id"], :name => "index_reports_on_resolver_user_id"
  add_index "reports", ["status"], :name => "index_reports_on_status"

  create_table "rpush_apps", :force => true do |t|
    t.string   "name",                                   :null => false
    t.string   "environment"
    t.text     "certificate"
    t.string   "password"
    t.integer  "connections",             :default => 1, :null => false
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "type",                                   :null => false
    t.string   "auth_key"
    t.string   "client_id"
    t.string   "client_secret"
    t.string   "access_token"
    t.datetime "access_token_expiration"
  end

  create_table "rpush_feedback", :force => true do |t|
    t.string   "device_token", :limit => 64, :null => false
    t.datetime "failed_at",                  :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "app_id"
  end

  add_index "rpush_feedback", ["device_token"], :name => "index_rapns_feedback_on_device_token"

  create_table "rpush_notifications", :force => true do |t|
    t.integer  "badge"
    t.string   "device_token",      :limit => 64
    t.string   "sound",                                 :default => "default"
    t.string   "alert"
    t.text     "data"
    t.integer  "expiry",                                :default => 86400
    t.boolean  "delivered",                             :default => false,     :null => false
    t.datetime "delivered_at"
    t.boolean  "failed",                                :default => false,     :null => false
    t.datetime "failed_at"
    t.integer  "error_code"
    t.text     "error_description"
    t.datetime "deliver_after"
    t.datetime "created_at",                                                   :null => false
    t.datetime "updated_at",                                                   :null => false
    t.boolean  "alert_is_json",                         :default => false
    t.string   "type",                                                         :null => false
    t.string   "collapse_key"
    t.boolean  "delay_while_idle",                      :default => false,     :null => false
    t.text     "registration_ids",  :limit => 16777215
    t.integer  "app_id",                                                       :null => false
    t.integer  "retries",                               :default => 0
    t.string   "uri"
    t.datetime "fail_after"
    t.boolean  "processing",                            :default => false,     :null => false
    t.integer  "priority"
    t.text     "url_args"
    t.string   "category"
  end

  add_index "rpush_notifications", ["app_id", "delivered", "failed", "deliver_after"], :name => "index_rapns_notifications_multi"
  add_index "rpush_notifications", ["delivered", "failed"], :name => "index_rpush_notifications_multi"

  create_table "schools", :force => true do |t|
    t.string   "type",            :limit => 255,                                    :null => false
    t.string   "name",            :limit => 255,                                    :null => false
    t.string   "address",         :limit => 255
    t.string   "city",            :limit => 255
    t.string   "state",           :limit => 255
    t.string   "zip",             :limit => 255
    t.string   "country",         :limit => 255, :default => "United States"
    t.float    "latitude"
    t.float    "longitude"
    t.boolean  "validated_admin",                :default => false
    t.boolean  "homeschool",                     :default => false
    t.datetime "created_at",                     :default => '2015-10-01 04:00:00'
    t.integer  "user_count",                     :default => 0
  end

  add_index "schools", ["created_at"], :name => "index_schools_on_created_at"
  add_index "schools", ["validated_admin"], :name => "index_schools_on_validated_admin"

  create_table "schools_users", :force => true do |t|
    t.integer  "user_id",                   :null => false
    t.integer  "school_id",                 :null => false
    t.string   "teacher",    :limit => 255
    t.integer  "grade"
    t.datetime "created_at"
  end

  add_index "schools_users", ["grade"], :name => "index_schools_users_on_grade"
  add_index "schools_users", ["school_id"], :name => "index_schools_users_on_school_id"
  add_index "schools_users", ["user_id"], :name => "index_schools_users_on_user_id"

  create_table "secondary_filter_keywords", :force => true do |t|
    t.string  "keyword"
    t.integer "severity"
  end

  create_table "tips", :force => true do |t|
    t.string  "title",                      :null => false
    t.integer "order_index", :default => 1
  end

  add_index "tips", ["order_index"], :name => "index_tips_on_order_index"

  create_table "trade_comments", :force => true do |t|
    t.integer  "trade_id",                                            :null => false
    t.integer  "item_id"
    t.integer  "user_id",                                             :null => false
    t.string   "comment",          :limit => 255
    t.float    "price"
    t.string   "status",           :limit => 255, :default => "WAIT"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.boolean  "is_meeting_place",                :default => false
  end

  add_index "trade_comments", ["trade_id"], :name => "index_trade_comments_on_trade_id"
  add_index "trade_comments", ["user_id"], :name => "index_trade_comments_on_user_id"

  create_table "trades", :force => true do |t|
    t.integer  "buyer_id",                                                       :null => false
    t.integer  "seller_id",                                                      :null => false
    t.string   "status",                      :limit => 255, :default => "OPEN", :null => false
    t.boolean  "buyer_agree",                                :default => false
    t.boolean  "seller_agree",                               :default => false
    t.datetime "created_at",                                                     :null => false
    t.datetime "updated_at",                                                     :null => false
    t.integer  "waiting_for_user_id"
    t.integer  "last_meeting_place_set_by",                  :default => 0
    t.boolean  "buyer_parent_approve",                       :default => false
    t.boolean  "seller_parent_approve",                      :default => false
    t.datetime "completed_at"
    t.boolean  "sent_completed_notification",                :default => false
    t.boolean  "completion_confirmed",                       :default => false
    t.boolean  "buyer_packed",                               :default => false
    t.boolean  "seller_packed",                              :default => false
    t.string   "buyer_real_name"
    t.string   "seller_real_name"
    t.text     "denied"
    t.integer  "reason_ended",                               :default => 0
    t.integer  "ended_by_user_id",                           :default => 0
    t.string   "other_reason"
  end

  add_index "trades", ["buyer_id"], :name => "index_trades_on_buyer_id"
  add_index "trades", ["completion_confirmed"], :name => "index_trades_on_completion_confirmed"
  add_index "trades", ["seller_id"], :name => "index_trades_on_seller_id"

  create_table "trades_items", :force => true do |t|
    t.integer "trade_id",                 :null => false
    t.integer "item_id",                  :null => false
    t.integer "seller_id",                :null => false
    t.integer "quantity",  :default => 1
  end

  add_index "trades_items", ["item_id"], :name => "index_trades_items_on_item_id"
  add_index "trades_items", ["trade_id"], :name => "index_trades_items_on_trade_id"

  create_table "user_locations", :force => true do |t|
    t.integer  "user_id"
    t.string   "address",    :limit => 255
    t.string   "city",       :limit => 255
    t.string   "state",      :limit => 255
    t.string   "zip",        :limit => 255
    t.string   "country",    :limit => 255, :default => "United States"
    t.float    "latitude"
    t.float    "longitude"
    t.boolean  "is_primary",                :default => false
    t.string   "address2"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.boolean  "reviewed",                  :default => true
  end

  add_index "user_locations", ["reviewed"], :name => "index_user_locations_on_reviewed"
  add_index "user_locations", ["user_id", "is_primary"], :name => "index_user_locations_on_user_id_and_is_primary"
  add_index "user_locations", ["user_id"], :name => "index_user_locations_on_user_id"

  create_table "user_notification_tokens", :force => true do |t|
    t.integer  "user_id",                      :null => false
    t.string   "token"
    t.string   "platform_type", :limit => 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_phones", :force => true do |t|
    t.integer  "user_id",                                       :null => false
    t.string   "number",     :limit => 255,                     :null => false
    t.string   "phone_type", :limit => 255, :default => "HOME"
    t.boolean  "is_primary",                :default => false
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
  end

  add_index "user_phones", ["user_id"], :name => "index_user_phones_on_user_id"

  create_table "user_relationships", :force => true do |t|
    t.integer "primary_user_id"
    t.integer "secondary_user_id"
    t.string  "relationship_type", :limit => 55
  end

  add_index "user_relationships", ["primary_user_id"], :name => "index_parents_children_on_parent_id"
  add_index "user_relationships", ["relationship_type"], :name => "index_user_relationships_on_relationship_type"
  add_index "user_relationships", ["secondary_user_id"], :name => "index_parents_children_on_child_id"

  create_table "user_trackings", :force => true do |t|
    t.integer  "user_id",                  :null => false
    t.string   "ip",        :limit => 255
    t.string   "system",    :limit => 255
    t.string   "browser",   :limit => 255
    t.string   "continent", :limit => 255
    t.string   "country",   :limit => 255
    t.string   "city",      :limit => 255
    t.string   "state",     :limit => 255
    t.string   "zip",       :limit => 255
    t.string   "timezone",  :limit => 255
    t.datetime "login_at"
    t.datetime "logout_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "encrypted_password",       :limit => 255,        :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                  :default => 0,     :null => false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",       :limit => 255
    t.string   "last_sign_in_ip",          :limit => 255
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.string   "type",                     :limit => 64,                            :null => false
    t.string   "user_name",                :limit => 64,                            :null => false
    t.string   "first_name",               :limit => 64,                            :null => false
    t.string   "last_name",                :limit => 64
    t.text     "interests",                :limit => 2147483647
    t.date     "birthdate"
    t.string   "gender",                   :limit => 255
    t.integer  "current_school_id"
    t.integer  "primary_user_location_id"
    t.string   "profile_image",            :limit => 255
    t.string   "profile_image_name",       :limit => 255
    t.string   "teacher",                  :limit => 255
    t.integer  "grade"
    t.string   "timezone",                 :limit => 255
    t.integer  "item_count",                                     :default => 0
    t.integer  "trade_count",                                    :default => 0
    t.integer  "parent_id",                                                         :null => false
    t.integer  "reported_count",                                 :default => 0
    t.integer  "reporter_count",                                 :default => 0
    t.boolean  "banned",                                         :default => false
    t.boolean  "account_confirmed",                              :default => false, :null => false
    t.boolean  "business_card_note_sent",                        :default => false
    t.integer  "item_total",                                     :default => 0
    t.integer  "open_item_total",                                :default => 0
    t.string   "driver_license_image"
    t.boolean  "is_test_user",                                   :default => false
    t.boolean  "finished_registering",                           :default => false
    t.boolean  "is_parent_email",                                :default => true
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["is_test_user"], :name => "index_users_on_is_test_user"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["type"], :name => "index_users_on_type"
  add_index "users", ["user_name"], :name => "index_users_on_user_name"

  create_table "zip_codes", :force => true do |t|
    t.string  "zip",                 :limit => 55
    t.string  "state_type",          :limit => 24
    t.string  "primary_city"
    t.string  "acceptable_cities",   :limit => 255
    t.string  "unacceptable_cities", :limit => 255
    t.string  "state",               :limit => 55
    t.string  "county",              :limit => 55
    t.integer "timezone"
    t.string  "area_codes",          :limit => 127
    t.float   "latitude",                           :null => false
    t.float   "longitude",                          :null => false
    t.string  "world_region"
    t.string  "country",             :limit => 127
  end

  add_index "zip_codes", ["country", "state"], :name => "index_zip_codes_on_country_and_state"
  add_index "zip_codes", ["primary_city"], :name => "index_zip_codes_on_primary_city"
  add_index "zip_codes", ["state"], :name => "index_zip_codes_on_state"
  add_index "zip_codes", ["timezone"], :name => "index_zip_codes_on_timezone"
  add_index "zip_codes", ["zip"], :name => "index_zip_codes_on_zip"

end
