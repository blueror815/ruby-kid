module Users
  module Notifications
    class TradePickSomethingElse < TradeBasic

      def starred
        true
      end

      def copy_identifier
        :trading_picked_something_else
      end
    end
  end
end
