class UserJoinedMessageWorker
  include Sidekiq::Worker
  #check the user_joined_message_worker comments
  sidekiq_options unique: true, unique_args: ->(args) { [ args.first ] }, log_duplicate_payload: true, unique_job_expiration: 120 * 60 # 2 hours

  def perform(user_id)
  	puts "------new use id in Worker for sidekiq------W/#{user_id}"
    User.sidekiq_generate_message_new_to_circle(user_id)
  end
end
