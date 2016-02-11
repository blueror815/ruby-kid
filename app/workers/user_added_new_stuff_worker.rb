class UserAddedNewStuffWorker
  include Sidekiq::Worker
  #unique and unique args will make it so two of the same sidekiq job can't be run at the same time.
  #unique args makes it so uniqueness only applies to the same user being called.
  #unique_job_expiration makes it so the job can only be ran 
  sidekiq_options unique: true, unique_args: ->(args) { [ args.first ] }, log_duplicate_payload: true, unique_job_expiration: 120 * 60 # 2 hours

  def perform(user_id)
    User.sidekiq_tell_friends_new_stuff(user_id)
  end
end
