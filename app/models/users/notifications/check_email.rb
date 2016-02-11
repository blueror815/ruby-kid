module Users
  module Notifications
    class CheckEmail < ::Users::Notification

      before_save :set_defaults

      def copy_identifier
        :check_email_push
      end

      protected

      def set_defaults
        super
        self.expires_at = (self.created_at || Time.now) + 5.minutes
      end

      def get_type
        :social
      end
    end
  end
end
