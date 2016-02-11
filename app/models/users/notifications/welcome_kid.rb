module Users
  module Notifications
    class WelcomeKid < ::Users::Notification

      def copy_identifier
        :welcome_kid_path
      end

      protected

      def get_type
        :welcome_kid
      end
    end
  end
end
