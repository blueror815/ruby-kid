module Users
  module Notifications
    class IsFollowing < ::Users::Notification

      def should_be_deleted_after_view?
        true
      end

      def copy_identifier
        :notification_is_following
      end

      def get_type
        :is_following
      end

    end
  end
end
