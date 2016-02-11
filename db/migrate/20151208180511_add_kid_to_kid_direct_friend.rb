class AddKidToKidDirectFriend < ActiveRecord::Migration
  def change
    id = :kid_to_kid_friend_direct
    nt = ::NotificationText.where(identifier: id ).first
    nt ||= ::NotificationText.new(identifier: id, language:'en', non_tech_description: 'This is direct Add Friend request from Child A to Child B')
    nt.attributes = {title: "%{sender_name} Wants to be Friend", subtitle:'', push_notification: "%{sender_name} wants to be friends.\nDon't leave %{sender_object_form}
      hanging!"}
    nt.save

    now_id = :child_is_now_friend
    if ::NotificationText.where(identifier: now_id ).count == 0
      ['Cool! You are now friends with %{send_user_name}', 'Check out %{sender_possessive_form} stuff!'].each do|push_text|
        puts "+ push text #{push_text}"
        ::NotificationText.create(identifier: now_id, language:'en',
          non_tech_description: 'To both Child A to Child B who just became friends',
          title: '%{sender_user_name} is Your Friend!', subtitle:'Check out their shop', push_notification: push_text )
      end
    end

    old_id = :kid_to_kid_friend
    ::NotificationText.where(identifier: old_id).delete_all
    ["%{sender_name} wants to be friends. Don't leave %{sender_object_form} hanging!",
      "%{sender_name} found you! More friends, more trades, more fun.",
      "%{sender_name} wants to Follow you! Log in to say, \"Yes\"." ].each do|push_text|
      puts "+ push text #{push_text}"
      ::NotificationText.create( identifier: old_id, language:'en',
        non_tech_description: 'This message is sent to kid who wants to add friend',
        title: 'Wait for Parent to Approval Your Friend', subtitle: 'Tell Your Parent',
        push_notification: push_text )
    end

  end
end
