module Users
  module Notifications
    class TradeApprovedSeller < TradeBasic

      def copy_identifier
        :trading_trade_beta_parent_approved
      end

      def should_be_deleted_after_view?
        false
      end

      def action_icon
        trade.waiting_for_user_id == recipient_user_id ? super : 'other'
      end
    end
  end
end
