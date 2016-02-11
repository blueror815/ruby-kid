module Users
  module Notifications
    class HasAnswer < ::Users::Notification

      def starred
        true
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
        :buying_question_reply
      end

      def get_type
        :has_answer
      end

    end
  end
end
