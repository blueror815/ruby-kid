module Users
  module Notifications
    class TradeParentNotApprovedSeller < TradePassive

      def copy_identifier
        :trading_trade_parent_not_approved_seller
      end

      def should_be_deleted_after_view
        true
      end

    end
  end
end
