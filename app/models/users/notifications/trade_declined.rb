module Users
  module Notifications
    class TradeDeclined < TradeBasic

      before_save :set_defaults

      def copy_identifier
        :trading_trade_declined
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

      protected

      def set_defaults
        super
        self.expires_at = (self.created_at || Time.now) + 1.day
      end
    end
  end
end