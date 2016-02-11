module Users
  module Notifications
    class LikeItem < ::Users::Notification

      before_save :set_defaults

      def copy_identifier
        :item_friends_like_item
      end

      def should_be_deleted_after_view?
        false
      end

      def should_be_flagged_viewed?
        true
      end

      def expire_after_view?
        if self.expires_at.nil? and self.status.eql? "VIEWED"
          true
        else
          false
        end
      end

      def action_icon
        'like'
      end

      protected

      def set_defaults
        puts "-------set defualts for likeitem.rb------W/"
        super
        self.uri = "/stores/#{self.sender_user_id}"
        #self.expires_at = (self.created_at || Time.now) + 5.days
      end

      def get_type
        :likes_item
      end

    end
  end
end
