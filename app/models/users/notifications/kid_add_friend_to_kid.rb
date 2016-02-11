module Users
  module Notifications
    class KidAddFriendToKid < ::Users::Notification

      REQUIRES_PARENT_APPROVAL_KEY = 'requires_parent_approval'

      def copy_identifier
        (local_references[REQUIRES_PARENT_APPROVAL_KEY] || ::Users::FriendRequest::REQUIRES_PARENT_APPROVAL) ? :kid_to_kid_friend : :kid_to_kid_friend_direct
      end

      def get_type
        :friend_kid
      end

      # The requires_parent_approval flag of the FriendRequest is passed onto the created or existing notifications,
      # so they can use in conditions to determine the other data according to flag.
      # @return <boolean> whether new record is created
      def self.create_if_needed(friend_request)
        params = {recipient_user_id: friend_request.recipient_user_id, sender_user_id: friend_request.requester_user_id}
        puts "------params for KidAddFriendToKid-------W/#{params}"
        if (list = where(params) ).empty?
          note = create( params.merge({uri: "/friend_request/#{friend_request.id}",
            related_model_type: '::Users::FriendRequest', related_model_id: friend_request.id,
            local_references_code: JSON.dump({REQUIRES_PARENT_APPROVAL_KEY => friend_request.requires_parent_approval?}) }) )
          puts "-----note for KidAddFriendToKid-------W/#{note}"
          # ::Users::UserNotificationToken.send_push_notifications_to(friend_request.recipient_user_id, note.text_for_push_notification )
          true
        else
          list.each{|note| note.set_local_reference!(REQUIRES_PARENT_APPROVAL_KEY, friend_request.requires_parent_approval?) }
          false
        end
      end

    end
  end
end
