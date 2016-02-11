class AddNeverPostedNotificationTexts < ActiveRecord::Migration
  def up
    add_index_unless_exists :notification_texts, :identifier

    base_attrs = { identifier: ::Users::Notifications::ChildNeverPosted.new.copy_identifier, language:'en',
                   non_tech_description:'When registered child has set profile image but never posted, sent every 24 hrs.' }
    [ ["Don't wait for something to happen... make it happen!", 'Post, share, start a trade!'],
      ['Can you post 5 items in 5 minutes?', 'Bet you can!'],
      ['Everyone loves getting an invitation.', 'Invite friends to join you on KidsTrade now!'],
      ['Post a few things. Invite a few friends.', "You'll be trading your way to new stuff in no time!"],
      ['Getting new stuff is easy!', 'Post. Shared. Trade. Repeat.'],
      ['You gotta post stuff to get stuff!', "Let's see what you've got."],
      ['Stop! Look around.', "See anything you don't use anymore? Post it!"]
    ].each do|pair|
      if ::NotificationText.where(identifier: base_attrs[:identifier], title: pair[0] ).count.zero?
        ::NotificationText.create(base_attrs.merge({title: pair[0], subtitle:pair[1], push_notification: pair[0] }) )
      end
    end
  end

  def down
  end
end
