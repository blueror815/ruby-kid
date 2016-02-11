##
# User-based status checks one day later.  Be careful whether the user should be the Parent or Child.
module Jobs
  class UserCheck < Struct.new(:user_id)

    TIME_LENGTH = 1.day

    #######################
    # Delayed job methods

    def perform
    end

    def max_attempts
      3
    end

    def queue_name
      'user_checks_queue'
    end

    ##
    # If morning time, some time in afternoon.  Else, 1 day later.
    def preferred_time
      (Time.now.hour < 17) ? Time.now.beginning_of_day + 13.hours + rand(4).hours : TIME_LENGTH.from_now
    end

    def enqueue!
      Delayed::Job.enqueue( self, priority: 0, run_at: preferred_time)
    end

    #####################
    # Info

    def user
      User.find(user_id)
    end
  end
end