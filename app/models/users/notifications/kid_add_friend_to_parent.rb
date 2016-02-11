module Users
  module Notifications
    class KidAddFriendToParent < ::Users::Notification

      def copy_identifier
        :kid_to_parent_friend
      end

      def get_type
        :friend_parent
      end

      # @return <boolean> whether new record is created
      def self.create_if_needed(friend_request)
        params = {recipient_user_id: friend_request.recipient_parent_id, sender_user_id: friend_request.recipient_user_id}
        if where(params).empty?
          create( params.merge({uri: "/friend_request/#{friend_request.id}", related_model_type:
                                   '::Users::FriendRequest', related_model_id: friend_request.id }) )
          true
        else
          false
        end
      end

    end
  end
end
