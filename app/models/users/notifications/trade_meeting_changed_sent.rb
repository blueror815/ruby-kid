module Users
  module Notifications
    class TradeMeetingChangedSent < TradePassive

      def copy_identifier
        :trading_meeting_changed_sent
      end

    end
  end
end