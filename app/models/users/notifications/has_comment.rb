module Users
  module Notifications
    class HasComment < ::Users::Notification

      def starred
        true
      end

      def should_flag_viewed?
        false
      end

      def should_be_deleted_after_view?
        false
      end

      def expire_after_view?
        if self.expires_at.nil? and self.status.eql? "VIEWED"
          true
        else
          false
        end
      end

      def copy_identifier
        :selling_has_question
      end

      def get_type
        :has_comment
      end

      def action_icon
        'question'
      end

    end
  end
end
