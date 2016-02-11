module Users
  module Notifications
    class TradeMeetingAgreed < TradeBasic

      def copy_identifier
        :trading_meeting_agreed
      end

      def starred
        true
      end

    end
  end
end
