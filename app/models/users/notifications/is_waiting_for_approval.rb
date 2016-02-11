module Users
  module Notifications
    class IsWaitingForApproval < ::Users::Notification

      def copy_identifier
        :parenting_item_approval
      end

      def starred
        true
      end

      def should_flag_viewed?
        false
      end


      ##
      # Create, replace or remove IsWaitingForApproval notification.
      # return <::Users::Notifications::IsWaitingForApproval> could be nil if not a child or no pending items
      def self.update_approval_notification!(child, parent = nil)
        return nil if not child.is_a?(Child) || !child.should_contact_parent?
        #note = notification
        parent ||= child.parent
        note = sent_to(parent.id).where(sender_user_id: child.id).last
        pending_items_count = ::Item.pending_approval.where(user_id: child.id).count
        if pending_items_count > 0
          if note.nil?
            ::Jobs::ItemApprovalReminder.new(child.id).enqueue!
          end

          note ||= new(sender_user_id: child.id, recipient_user_id: parent.id,
                       uri: route = Rails.application.routes.url_helpers.inventory_approve_item_path(user_id: child.id),
                       related_model_type: child.class.to_s, related_model_id: child.id, status: 'WAIT'
          )
          note.created_at = Time.now
          note.save
          #create a notification for the child.
          if ::Users::Notifications::NagParentItem.where(recipient_user_id: child.id).empty?
            ::Users::Notifications::NagParentItem.create(sender_user_id: Admin.cubbyshop_admin.id, recipient_user_id: child.id)
          end
          if not parent.account_confirmed and ::Users::Notifications::ChildVerifyAccount.where(recipient_user_id: child.id).empty?
            ::Users::Notifications::ChildVerifyAccount.create(sender_user_id: Admin.cubbyshop_admin.id, recipient_user_id: child.id)
          end
        else
          note.destroy if note
          ::Users::Notifications::NagParentItem.where(recipient_user_id: child.id).delete_all
        end
        note
      end

      def context_specific_notification_text
        context_notification_text = super
        pending_items_count = ::Item.pending_approval.where(user_id: self.sender_user_id).count + ::Item.pending_account_confirmation.where(user_id: self.sender_user_id).count
        context_notification_text['%{pending_items_count}'] = pending_items_count.to_s
        context_notification_text['%{item_count_pluralize}'] = 'New Item'.pluralize(pending_items_count)
        context_notification_text
      end

      def get_type
        :parent_approval
      end

    end
  end
end
