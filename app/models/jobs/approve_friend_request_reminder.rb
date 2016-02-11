##
# Sent 24 hours after parent when 1st parent friend approval notification was sent a day ago but not yet approved.
module Jobs
  class ApproveFriendRequestReminder < UserCheck

    def perform
      BG_LOGGER.info "#{self.class.to_s} for user #{user.user_name}"
      friend_request = ::Users::FriendRequest.where(requester_user_id: user.id, status: ::Users::FriendRequest::STATUS[:sent_request_parent] ).last
      if friend_request
        self.class.generate_mail(friend_request)
      end
    end

    def self.generate_mail(friend_request, test_only = false)
      last_fr_nm = ::NotificationMail.where(related_type: 'friend_request', related_type_id: friend_request.id)
      if last_fr_nm.nil? || last_fr_nm.created_at + TIME_LENGTH < Time.now
        BG_LOGGER.info '%6d | %20s | %19s |' % [friend_request.requester_user_id, friend_request.requester.user_name,
                                                last_fr_nm ? last_fr_nm.created_at.to_s(:db) : '*new*' ]
        friend_request.create_notification_mail! if not test_only
      end
    end

    ##
    # Iterates over the items table to look for child w/ pending items who needs reminders to their parents.
    def self.run_checks(test_only = true)
      BG_LOGGER.info "** TEST ONLY **" if test_only
      ::Users::FriendRequest.
        where(requester_user_id: user.id, status: ::Users::FriendRequest::STATUS[:sent_request_parent] )
        where('created_at < ?', TIME_LENGTH.ago).all.each do|friend_request|
          generate_mail(friend_request, test_only)
      end
    end

  end
end