##
# Notification-based job, intended to check back on status of the Users::Notification
module Jobs
  class NotificationCheck < Struct.new(:notification_id)

    TIME_LENGTH = 1.day

    #######################
    # Delayed job methods

    def perform
    end

    def max_attempts
      3
    end

    def queue_name
      'notification_checks_queue'
    end

    ##
    # If 1st time, some time in afternoon.
    def preferred_time
      which_day =  if notification.created_at < TIME_LENGTH.ago
        (Time.now.hour < 17) ? Time.now : TIME_LENGTH.from_now
      else
        TIME_LENGTH.from_now
      end
      which_day.beginning_of_day + 13.hours + rand(4).hours
    end

    def enqueue!
      Delayed::Job.enqueue( self, priority: 0, run_at: preferred_time)
    end

    #####################
    # Info

    def notification
      ::Users::Notification.find(notification_id)
    end
  end
end