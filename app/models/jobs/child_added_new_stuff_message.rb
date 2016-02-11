module Jobs
  class ChildAddedNewStuffMessage < UserCheck

    TIME_LENGTH = 10.seconds

    def perform
      BG_LOGGER.info "#{self.class.to_s} for user #{user_id}"
      ::User.sidekiq_tell_friends_new_stuff(user_id)
    end

  end
end