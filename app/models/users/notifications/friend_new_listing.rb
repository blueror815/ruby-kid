module Users
  module Notifications
    class FriendNewListing < ::Users::Notification

      before_save :set_defaults

      def copy_identifier
        :item_friends_new_listing
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
        :friend_has_new_listing
      end

    end
  end
end
