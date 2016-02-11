##
# Important messages that need to stay on list but not starred, and should not be flagged as viewed
module Users
  module Notifications
    class TradePassive < TradeBasic

      def starred
        false
      end

      def should_flag_viewed?
        true
      end

      def action_icon
        'other'
      end

    end
  end
end