module Users
  module Notifications
    class NeedsAccountConfirm < ::Users::Notification

      before_create :change_uri

      def copy_identifier
        :needs_account_confirm
      end

      def starred
        true
      end

      def should_be_deleted_after_view?
        false
      end

      protected

      def change_uri
        self.uri = Rails.application.routes.url_helpers.account_confirmation_path
      end

    end
  end
end
