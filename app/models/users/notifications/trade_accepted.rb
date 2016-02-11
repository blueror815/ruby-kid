module Users
  module Notifications
    class TradeAccepted < TradeBasic

      def copy_identifier
        :trading_trade_accepted
      end

      def starred
        true
      end

    end
  end
end
