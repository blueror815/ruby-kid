module Users
  module Notifications
    class TradeFromPast < TradeBasic

      def copy_identifier
        :trade_from_past
      end

      def breathing?
        false
      end
    end
  end
end
