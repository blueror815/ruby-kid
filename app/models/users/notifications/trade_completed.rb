module Users
  module Notifications
    class TradeCompleted < TradeBasic

      def copy_identifier
        :trading_trade_completed
      end

      def action_icon
        'other'
      end

    end
  end
end