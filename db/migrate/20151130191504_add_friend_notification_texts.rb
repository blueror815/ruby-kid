class AddFriendNotificationTexts < ActiveRecord::Migration
  def up
    change_column(:notification_texts, :push_notification, :text )
    nt = ::NotificationText.where(identifier: ::Users::Notifications::KidAddFriendToKid.new.copy_identifier ).first
    if nt
      puts ".. updating push_notification of #{nt.identifier}"
      nt.update_attributes(push_notification:"%{sender_name} wants to be friends. Don't leave %{sender_object_form} hanging!\n%{sender_name} found you! More friends, more trades, more fun.\n%{sender_name} wants to Follow you! Log in to say, \"Yes\"." )
    end
  end

  def down
  end
end
