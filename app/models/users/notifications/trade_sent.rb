module Users
  module Notifications
    class TradeSent < TradePassive

      def copy_identifier
        :trading_trade_reply_sent
      end

    end
  end
end
