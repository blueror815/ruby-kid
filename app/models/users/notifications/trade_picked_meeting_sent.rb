module Users
  module Notifications
    class TradePickedMeetingSent < TradePassive

      def copy_identifier
        :trading_picked_meeting_sent
      end
    end
  end
end