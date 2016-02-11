##
# Sent every 24 hours after child has picked avatar but never posted.
module Jobs
  class ChildNeverPostedCheck < UserCheck

    def perform
      return unless user.is_a?(::Child) && (user.profile_image || user.profile_image_name.present?)

      BG_LOGGER.info "#{self.class.to_s} for user #{user.user_name}"
      self.class.check_and_notify(user, false)
    end

    def self.check_and_notify(user, test_only = true)
      item_count = ::Item.where(user_id: user.id).count
      if item_count < 1
        BG_LOGGER.info "-> Push notification to #{user.user_name}, test_only #{test_only}"
        unless test_only
          note = ::Users::Notifications::ChildNeverPosted.where(recipient_user_id: user.id).not_deleted.first
          note ||= ::Users::Notifications::ChildNeverPosted.create(
            sender_user_id: ::Admin.cubbyshop_admin.id, recipient_user_id: user.id, related_model_type: 'User',
            related_model_id: user.id
          )
          note.send_push_notification if !note.new_record?
        end
        new(user.id).enqueue!
      end
    end

    ##
    # Iterates over the users table to look for child w/ .
    def self.run_checks(test_only = true)
      BG_LOGGER.info "** TEST ONLY **" if test_only
      Child.where('last_sign_in_at IS NOT NULL AND profile_image_name NOT NULL AND created_at < ?', TIME_LENGTH.ago ).each do|child|
        check_and_notify(child, test_only)
      end
    end

  end
end