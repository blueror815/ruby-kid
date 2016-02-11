module Users
  module Notifications
    class TradeParentApprovalNeededBuyer < TradePassive

      def copy_identifier
        :trading_trade_parent_approval_needed_buyer
      end

      def should_be_deleted_after_view?
        false
      end

    end
  end
end
