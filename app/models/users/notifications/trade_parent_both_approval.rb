module Users
  module Notifications
    class TradeParentBothApproval < TradeBasic

      def copy_identifier
        :trading_trade_parent_both_approval
      end

      def starred
        true
      end

      def should_flag_viewed?
        false
      end

      def should_be_deleted_after_view?
        false
      end

    end
  end
end
