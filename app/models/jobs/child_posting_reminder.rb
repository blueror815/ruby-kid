##
# Sent 24 hours after child logged in and child hasn’t posted yet.
module Jobs
  class ChildPostingReminder < UserCheck

    def perform
      BG_LOGGER.info "#{self.class.to_s} for user #{user.user_name}"
      if user.created_at + TIME_LENGTH < Time.now && Item.owned_by(user).count == 0
        self.class.generate_mail(user)
      end
    end

    def self.ending_time_boundary(user)
      (user.last_sign_in_at || user.created_at) + TIME_LENGTH
    end

    def self.generate_mail(user, test_only = false)
      recent_mail_count = ::NotificationMail.where('related_type=? AND related_type_id=? AND created_at > ?',
        self.to_s, user.id, ending_time_boundary(user) ).count
      if recent_mail_count == 0
        BG_LOGGER.info '%6d | %20s | %19s |' % [user.id, user.user_name, user.created_at.to_s(:db)]
        ::NotificationMail.create_from_mail(Admin.cubbyshop_admin.id, user.parent_id, ::UserMailer.child_posting_reminder(user), self.to_s, user.id ) if not test_only
      end
    end

    ##
    # Iterates over the users table to look for child who needs posting reminders to their parents.
    def self.run_checks(test_only = true)
      BG_LOGGER.info "** TEST ONLY **" if test_only
      Child.where(['last_sign_in_at IS NOT NULL AND last_sign_in_at < ?', TIME_LENGTH.ago] ).each do|child|
        if Item.owned_by(child) == 0
          generate_mail(child, test_only)
        end
      end
    end

  end
end