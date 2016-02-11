##
# Attributes:
#   follower_user_id: the user who's interested in the merchant's items
#   user_id: the merchant user who has other users following.
module Stores
  class Following < ActiveRecord::Base
    self.table_name = 'followers_users'

    attr_accessible :user_id, :follower_user_id, :last_traded_at, :friend_request

    belongs_to :user
    belongs_to :following_user, :class_name => 'User', :foreign_key => 'follower_user_id'

    after_create :create_notification! ##, :if => Proc.new {|following| not following.friend_request}

    FOLLOWING_TITLE = "Is Following Your Shop"

    ##
    # Removes all related notifications between this follower and store owner.
    def self.remove_following_notifications!(follower_user_id, user_id)
      ::Users::Notification.delete_all( sender_user_id: follower_user_id, recipient_user_id: user_id, title: FOLLOWING_TITLE )
    end

    def create_notification!
      return nil if user.nil?
      self.class.remove_following_notifications!(follower_user_id, user_id)

      #UserMailer.is_following(self.following_user, self.user)

      if friend_request
        ::Users::Notifications::ChildIsNowFriend.create(
            sender_user_id: follower_user_id, recipient_user_id: user_id, related_model_type: 'User', related_model_id: user_id
        )

      else
        ::Users::Notifications::IsFollowing.new(sender_user_id: follower_user_id, recipient_user_id: user_id,
                                     title: FOLLOWING_TITLE, uri: Rails.application.routes.url_helpers.store_path(user_id),
                                     related_model_type: 'User', related_model_id: user_id
        )
      end
    end

    ##
    # Queries for the latest trade between the 2 users, and sets this last_traded_at
    def update_last_traded_at!
      last_trade = ::Trading::Trade.where("buyer_id IN (?, ?) AND seller_id IN (?, ?)", user_id, follower_user_id, user_id, follower_user_id).last
      if last_trade && (last_trade.accepted? || last_trade.completed?)
        update_attributes( last_traded_at: last_trade.updated_at )
      end
    end

  end
end
