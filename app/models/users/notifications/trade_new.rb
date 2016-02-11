##
# For both the buyer and seller: the one for buyer being passive notification waiting for seller's action.
module Users
  module Notifications
    class TradeNew < TradeBasic

      after_create :create_reminder!

      def starred
        !is_sender_the_merchant?
      end

      def should_flag_viewed?
        is_sender_the_merchant?
      end

      def copy_identifier
        is_sender_the_merchant? ? :trading_new_trade_from_merchant : :trading_new_trade_from_customer
      end

      # def text_for_push_notification
      #   title
      # end

      def action_icon
        starred ? super : 'other'
      end

      def create_reminder!
        ::Jobs::NewTradeReminder.new(self.id).enqueue!
      end

    end
  end
end
