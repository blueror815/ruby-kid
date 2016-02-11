##
# Sent every 24 hours after child has picked avatar but never posted.
module Jobs
  class StatsRecalculation < UserCheck

    def perform
      return unless user.is_a?(::Child)

      BG_LOGGER.info "#{self.class.to_s} for user #{user.user_name}"
      self.class.update_if_needed(user, false)
    end

    # Immediate
    def preferred_time
      Time.now
    end

    def self.update_if_needed(user, test_only = true)
      trade_count = user.fetch_trade_count
      if trade_count != user.trade_count
        BG_LOGGER.info "-> #{user.user_name}(#{user.id}) current trade_count #{user.trade_count} vs #{trade_count}"
        unless test_only
          user.trade_count = trade_count
          user.save
        end
      end
    end

    ##
    # Iterates over the users table to look for child w/ .
    def self.run_checks(test_only = true)
      BG_LOGGER.info "** TEST ONLY **" if test_only
      already_checked_ids = Set.new
      ::Trading::Trade.accepted.each do|trade|
        unless already_checked_ids.include?(trade.buyer_id)
          update_if_needed(trade.buyer, test_only)
          already_checked_ids << trade.buyer_id
        end
        unless already_checked_ids.include?(trade.seller_id)
          update_if_needed(trade.seller, test_only)
          already_checked_ids << trade.seller_id
        end
      end.count
    end

  end
end