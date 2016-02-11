##
# Sent 24 hours after parent when 1st parent item approval notification was sent a day ago but not yet approved.
module Jobs
  class ItemApprovalReminder < UserCheck

    def perform
      BG_LOGGER.info "#{self.class.to_s} for user #{user.user_name}"
      first_approval = ::Users::Notifications::IsWaitingForApproval.where(recipient_user_id: user.parent_id).first
      if first_approval && first_approval.created_at + TIME_LENGTH < Time.now && Item.owned_by(user).pending.count > 0
        self.class.generate_mail(user, first_approval)
      end
    end

    def self.generate_mail(user, item_approval_note = nil, test_only = false)
      item_approval_note ||= ::Users::Notifications::IsWaitingForApproval.where(recipient_user_id: user.parent_id).first
      time_mark = item_approval_note.try(:created_at) || Item.owned_by(user).first.try(:created_at) || user.created_at
      recent_mail_count = ::NotificationMail.where('related_type=? AND related_type_id=? AND created_at > ?',
                                                   self.to_s, user.id, time_mark + TIME_LENGTH ).count
      if recent_mail_count == 0
        puts '%6d | %20s | %19s |' % [user.id, user.user_name, time_mark.to_s(:db)]
        ::NotificationMail.create_from_mail(Admin.cubbyshop_admin.id, user.parent_id, ::UserMailer.item_approval_reminder(user), self.to_s, user.id ) if not test_only
      end
    end

    ##
    # Iterates over the items table to look for child w/ pending items who needs reminders to their parents.
    def self.run_checks(test_only = true)
      BG_LOGGER.info "** TEST ONLY **" if test_only
      Item.pending.select('id, user_id, status').group_by(&:user_id).each_pair do|user_id, item_list|
        item_approval_note = ::Users::Notifications::IsWaitingForApproval.where(sender_user_id: user_id).includes(:recipient).first
        if item_approval_note && item_approval_note.created_at + TIME_LENGTH < Time.now
          generate_mail(item_approval_note.recipient, item_approval_note, test_only)
        end
      end
    end

  end
end