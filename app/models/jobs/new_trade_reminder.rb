##
# Sent 24 hours after user A sends trade request a day ago but not yet responded.
module Jobs
  class NewTradeReminder < NotificationCheck

    def perform
      return if not notification.waiting?
      BG_LOGGER.info "#{self.class.to_s} for notification #{notification_id} to #{notification.recipient_user_id}"

      self.class.push_notification(notification, false)

    end

    def self.push_notification(notification, test_only = true)
      BG_LOGGER.info 'Notification(%6d) | %s | %20s | last login: %s' % [notification.id, notification.status, notification.recipient.user_name,
        notification.recipient.last_sign_in_at.try(:to_s, :db) ]
      unless test_only
        if notification.recipient.user_notification_tokens.count > 0
          if notification.recipient.last_sign_in_at.nil? || Time.now > notification.recipient.last_sign_in_at + TIME_LENGTH
            no_login_note = ::Users::Notifications::ChildNoLoginAfterTrade.new(
              recipient_user_id: notification.recipient_user_id, related_model_type: notification.related_model_type,
              related_model_id: notification.related_model_id)
            BG_LOGGER.info '\_ %s(%d) being sent to %s: %s' % [no_login_note.copy_identifier, ::NotificationText.where(identifier: no_login_note.copy_identifier).count, notification.recipient.user_name, no_login_note.text_for_push_notification]
            no_login_note.send_push_notification

          else
            BG_LOGGER.info '\_ %s being sent to %s: %s' % [notification.copy_identifier, notification.recipient.user_name, notification.text_for_push_notification]
            notification.send_push_notification
          end
          new(notification.id).enqueue!
        else
          BG_LOGGER.info ' \_ %s does not have registered tokens to push notifications'
        end
      end
    end

    ##
    # Iterates over the notifications to look for waiting trades.
    def self.run_checks(test_only = true)
      BG_LOGGER.info "** TEST ONLY **" if test_only

      ::Users::Notifications::TradeNew.where('status = ? AND created_at < ?', ::Users::Notification::Status::WAIT, TIME_LENGTH.ago).includes(:recipient).all.each_with_index do|note, idx|
        push_notification(note, test_only)
        if idx % 10 == 9 && !test_only
          BG_LOGGER.info "#{self} taking a break ..."
          sleep(5) # secs
        end
      end
    end

  end
end