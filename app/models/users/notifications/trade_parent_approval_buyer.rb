module Users
  module Notifications
    class TradeParentApprovalBuyer < TradeBasic

      after_create :create_notification_mail!

      def copy_identifier
        :trading_trade_parent_approval_buyer
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

      protected

      def create_notification_mail!
        related_type = 'trade_approval'
        recent_mail_count = ::NotificationMail.where(["recipient_user_id = ? AND sender_user_id = ? AND related_type = ? AND related_type_id = ? AND created_at > ?",
                                                      recipient_user_id, sender_user_id, related_type, related_model_id, 1.day.ago] ).count
        if recent_mail_count == 0
          ::NotificationMail.create_from_mail(sender_user_id, recipient_user_id, UserMailer.trade_approval(trade, self.sender), related_type )

        end

      end

    end
  end
end
