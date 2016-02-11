module Users
  module Notifications
    class ChildNoLoginAfterTrade < ::Users::Notification

      def copy_identifier
        :child_no_login_after_trade
      end

      def starred
        true
      end

      protected

      def set_defaults
        super
        self.uri = Rails.application.routes.url_helpers.new_item_path
      end

    end
  end
end