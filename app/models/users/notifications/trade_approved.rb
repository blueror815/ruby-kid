module Users
  module Notifications
    class TradeApproved < TradeBasic

      def copy_identifier
        if trade.is_buyer_side?(recipient_user_id)
          :trading_trade_alpha_parent_approved
        else
          :trading_trade_beta_parent_approved
        end
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
