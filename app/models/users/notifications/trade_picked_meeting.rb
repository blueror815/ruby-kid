module Users
  module Notifications
    class TradePickedMeeting < TradeBasic

      def copy_identifier
        :trading_picked_meeting
      end

      def starred
        true
      end
    end
  end
end