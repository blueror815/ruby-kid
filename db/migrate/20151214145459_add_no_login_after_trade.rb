class AddNoLoginAfterTrade < ActiveRecord::Migration
  def up

    ::NotificationText.where(identifier: [:trading_new_trade_from_customer, :trading_new_trade_from_merchant]).each do|new_trade_text|
      new_trade_text.update_attributes(title: '%{sender_name} Wants to Trade!')
      puts "#{new_trade_text.identifier}.title -> %{sender_name} Wants to Trade!"
    end

    base_attrs = { identifier: ::Users::Notifications::ChildNoLoginAfterTrade.new.copy_identifier, language:'en',
                   non_tech_description:'Reminder when child needs to respond to trade offer every 24 hrs when not logged in.' }
    [ ["Don't wait for something to happen... make it happen!", 'Post, share, start a trade!'],
      ['The best stuff goes quickly.', "See what's new and get it before it's gone!"],
      ['Can you post 5 items in 5 minutes?', 'Bet you can!'],
      ['Banish boredom!', "Find something that's \"new to you\" and get a trade going."],
      ["Who joined? What's up for grabs? Who's checking out your stuff?", 'Log in to find out!'],
      ["What's the one thing you've been wishing for?", 'Maybe someone just posted it!']
    ].each do|pair|
      if ::NotificationText.where(identifier: base_attrs[:identifier], title: pair[0] ).count.zero?
        ::NotificationText.create(base_attrs.merge({title: pair[0], subtitle:pair[1], push_notification: pair[0] }) )

      end
    end
  end

  def down
  end
end
