module Users
  module Notifications
    class ChildIsNowFriend < ::Users::Notification

      def copy_identifier
        :child_is_now_friend
      end

      def starred
        true
      end

      def expire_after_view?
        true
      end

      protected

      def set_defaults
        super
        self.uri = Rails.application.routes.url_helpers.stores_path(id: sender_user_id)
      end

    end
  end
end