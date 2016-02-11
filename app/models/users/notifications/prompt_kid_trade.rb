module Users
  module Notifications
    class PromptKidTrade < ::Users::Notification
      before_save :set_defaults

      def copy_identifier
        :push_note_trade_pls
      end

      def set_defaults
        super
        self.expires_at = (self.created_at || Time.now) + 1.minute
      end

    end
  end
end
