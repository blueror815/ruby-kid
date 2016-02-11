module Users
  module Notifications
    class BusinessCardPromptKid < ::Users::Notification

      def copy_identifier
        :business_card_kid
      end

      def should_be_deleted_after_view?
        false
      end

    end
  end
end
