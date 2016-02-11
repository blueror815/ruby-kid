##
# Sent 24 hours after parent when 1st parent item approval notification was sent a day ago but not yet approved.
module Jobs
  class VerifyAccountReminder < UserCheck

    def perform
      _parent = user.is_a?(Child) ? user.parent : user
      BG_LOGGER.info "#{self.class.to_s} for user #{_parent.user_name}"
      if not _parent.account_confirmed
        confirm_approval = ::Users::Notifications::NeedsAccountConfirm.where(recipient_user_id: _parent.id).last
        if confirm_approval && confirm_approval.created_at + TIME_LENGTH < Time.now
          self.class.generate_mail(_parent, confirm_approval)
        end
      end
    end

    def self.generate_mail(user, account_confirm_note = nil, test_only = false)
      account_confirm_note ||= ::Users::Notifications::NeedsAccountConfirm.where(recipient_user_id: user.id).last
      if account_confirm_note
        BG_LOGGER.info '%6d | %20s | %19s |' % [user.id, user.user_name, account_confirm_note.created_at.to_s(:db)]
        ::NotificationMail.create_from_mail(Admin.cubbyshop_admin.id, user.id, ::UserMailer.verify_account_reminder(user), self.to_s, user.id ) if not test_only
      end
    end

    ##
    # Iterates over the items table to look for child w/ pending items who needs reminders to their parents.
    def self.run_checks(test_only = true)
      BG_LOGGER.info "** TEST ONLY **" if test_only
      ::Users::Notifications::NeedsAccountConfirm.not_deleted.where('created_at < ?', TIME_LENGTH.ago).includes(:recipient).all.each do|note|
        if not note.recipient.account_confirmed
          generate_mail(note.recipient, note, test_only)
        end
      end
    end

  end
end