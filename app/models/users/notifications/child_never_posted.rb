module Users
  module Notifications
    class ChildNeverPosted < ::Users::Notification

      def copy_identifier
        :child_never_posted
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