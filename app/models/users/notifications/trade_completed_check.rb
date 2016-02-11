module Users
  module Notifications
    class TradeCompletedCheck < TradeBasic

      def starred
        true
      end

      def copy_identifier
        :trade_completed_check
      end

      def breathing?
        true
      end
    end
  end
end
