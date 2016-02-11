class ChangeChildIsNowFriendTitle < ActiveRecord::Migration
  def up
    now_id = :child_is_now_friend
    ::NotificationText.where(identifier: now_id ).delete_all

    ['Cool! You are now friends with %{send_name}', 'Check out %{sender_possessive_form} stuff!'].each do|push_text|
      puts "+ push text #{push_text}"
      ::NotificationText.create(identifier: now_id, language:'en',
                                non_tech_description: 'To both Child A to Child B who just became friends',
                                title: '%{sender_name} is Your Friend!', subtitle:'Check out their shop', push_notification: push_text )
    end
  end

  def down
  end
end
