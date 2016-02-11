module Users
  module Notifications
    class TradeParentNotApproved < TradePassive

      def copy_identifier
        :trading_trade_parent_not_approved_buyer
      end

      def should_be_deleted_after_view
        true
      end
    end
  end
end
