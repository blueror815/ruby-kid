module Users
  module Notifications
    class BusinessCardPromptParent < ::Users::Notification

      def copy_identifier
        :business_card_parent
      end

      def should_be_deleted_after_view?
        false
      end

    end
  end
end
