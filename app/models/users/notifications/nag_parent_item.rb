module Users
  module Notifications
    class NagParentItem < ::Users::Notification
      before_save :set_defaults

      def copy_identifier
        :nag_parent_item
      end

      def should_be_deleted_after_view?
        false
      end
    end
  end
end
