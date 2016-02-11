module Users
  module Notifications
    class TradeMeetingAgreedSent < TradePassive

      def copy_identifier
        :trading_meeting_agreed_sent
      end

    end
  end
end