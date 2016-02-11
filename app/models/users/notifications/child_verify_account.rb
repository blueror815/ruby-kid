module Users
  module Notifications
    class ChildVerifyAccount < ::Users::Notification
      before_save :set_defaults

      def copy_identifier
        :child_verify_account
      end

      def should_be_deleted_after_view?
        false
      end
    end
  end
end
