module Users
  module Notifications
    class TradeParentApprovalNeededSeller < TradePassive

      def copy_identifier
        :trading_trade_parent_approval_needed_seller
      end

      def should_be_deleted_after_view?
        false
      end

    end
  end
end
