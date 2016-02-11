##
# Sent 24 hours after parent registered and child hasn’t logged in
module Jobs
  class ChildLoginReminder < UserCheck

    def perform
      BG_LOGGER.info "#{self.class.to_s} for user #{user.user_name}"
      if user.created_at + TIME_LENGTH < Time.now && user.last_sign_in_at.nil?
        self.class.generate_mail(user)
      end
    end

    def self.generate_mail(user, test_only = false)
      recent_mail_count = ::NotificationMail.where('related_type=? AND related_type_id=? AND created_at > ?',
        self.to_s, user.id, user.created_at + TIME_LENGTH ).count
      if recent_mail_count == 0
        BG_LOGGER.info '%6d | %20s | %19s |' % [user.id, user.user_name, user.created_at.to_s(:db)]
        ::NotificationMail.create_from_mail(Admin.cubbyshop_admin.id, user.parent_id, ::UserMailer.child_login_reminder(user), self.to_s, user.id ) if not test_only
      end
    end

    ##
    # Iterates over the users table to look for child who needs login reminders to their parents.
    # For real
    def self.run_checks(test_only = true)
      BG_LOGGER.info "** TEST ONLY **" if test_only
      Child.where(['created_at < ? AND last_sign_in_at IS NULL', TIME_LENGTH.ago] ).each do|child|
        generate_mail(child, test_only)
      end
    end

  end
end