module Users
  module Notifications
    class NewToCircle < ::Users::Notification

      before_save :set_defaults

      def copy_identifier
        :item_friends_new_to_circle
      end

      def should_be_deleted_after_view?
        true
      end

      protected

      def set_defaults
        super
        self.expires_at = (self.created_at || Time.now) + 1.week
      end

      def get_type
        :social
      end

    end
  end
end
