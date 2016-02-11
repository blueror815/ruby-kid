module Users
  module Notifications
    class ChildNewItem < ::Users::Notification

      def copy_identifier
        :parenting_check_new_item
      end

      def starred
        true
      end

      def should_flag_viewed?
        false
      end


      ##
      # Create, replace or remove this notification.
      def self.update_notification!(item)
        child = item.user
        parent = child.parent
        return nil if !child.should_contact_parent? || parent.nil?

        note = sent_to(parent.id).where(sender_user_id: child.id).last

        # Don't send message to parent until app adds mapped action for this new type of message.
        # note ||= new(sender_user_id: child.id, recipient_user_id: parent.id,
        #              uri: route = Rails.application.routes.url_helpers.inventory_approve_item_path(user_id: child.id),
        #              related_model_type: child.class.to_s, related_model_id: child.id, status: 'WAIT'
        # )
        # note.created_at = Time.now
        # note.save

        # generate email
        related_type = get_type
        recent_mail_count = ::NotificationMail.where('recipient_user_id = ? AND sender_user_id = ? AND related_type = ? AND created_at > ?', parent.id, child.id, related_type, 1.day.ago ).count
        if recent_mail_count > 0
          puts " .. Parent #{parent.id} already has #{recent_mail_count} approval mail recently"
        elsif parent.email.present?
          ::NotificationMail.create_from_mail(item.user_id, parent.id, UserMailer.check_new_item(item, parent), related_type )
        end
        note
      end

      def get_type
        self.class.get_type
      end

      def self.get_type
        :parent_check_new_item
      end

      protected

      def set_defaults
        super
        self.uri = Rails.application.routes.url_helpers.store_path(id: sender_user_id)
      end

    end
  end
end
