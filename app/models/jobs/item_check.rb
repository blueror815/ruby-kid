##
# Item-based status checks soon after.
module Jobs
  class ItemCheck < Struct.new(:item_id)

    TIME_LENGTH = 10.seconds

    #######################
    # Delayed job methods

    def perform
    end

    def max_attempts
      3
    end

    def queue_name
      'item_checks_queue'
    end


    def enqueue!
      Delayed::Job.enqueue( self, priority: 0, run_at: TIME_LENGTH.from_now)
    end

    #####################
    # Info

    def item
      Item.find(item_id)
    end
  end
end