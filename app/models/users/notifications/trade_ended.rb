module Users
  module Notifications
    class TradeEnded < TradeBasic

      def copy_identifier
        :trading_trade_ended
      end

      def starred
        false
      end

      def should_flag_viewed?
        true
      end

      def should_be_deleted_after_view?
        true
      end

      def action_icon
        'other'
      end

    end
  end
end
