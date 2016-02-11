AUTO_APPROVE_ITEM_BATCH_SIZE = 50

task :auto_approve_items => :environment do
  puts "#############################"
  puts "# Auto Approve Items"
  puts Time.now.to_s(:db)
  latest_time = 1.second.ago
  total_pending_count = ::Item.pending.where(["created_at < ?", latest_time] ).count
  puts "# Total pending items since #{1.day.ago.to_s(:db) }"
  updated_count = 0
  while updated_count < total_pending_count do
    pending_items = ::Item.pending.where(["created_at < ?", latest_time] ).limit( AUTO_APPROVE_ITEM_BATCH_SIZE )
    puts "  -> activating items #{ pending_items.collect(&:id) }"
    #pending_items.update_all( status: ::Item::Status::OPEN )
    pending_items.each do |item|
      if ::Items::ItemInfo::REQUIRES_PARENT_APPROVAL == false || (not item.owner.nil? and not item.owner.parent.nil? and not item.owner).parents.first.nil? #and item.owner.parents.first.account_confirmed
        if ::Items::ItemInfo::REQUIRES_ACCOUNT_CONFIRMATION_TO_ACTIVATE == false || item.owner.parents.first.account_confirmed
          item.activate!

        else
          item.status = Item::Status::PENDING_ACCOUNT_CONFIRMATION
          item.save
          Sunspot.index item
        end
      else
        Item.where(id: item.id).update_all(status: Item::Status::PENDING_ACCOUNT_CONFIRMATION)
      end
    end
    updated_count += AUTO_APPROVE_ITEM_BATCH_SIZE
  end
end

##
# After an item created without parent approval requirement, notify parent via email
task :notify_to_check_items => :environment do
  puts "#############################"
  puts "# Notify to Check New Items"
  puts Time.now.to_s(:db)

  related_type = ::Users::Notifications::ChildNewItem.get_type
  notified_user_ids = Set.new # parent IDs
  ::Item.open_items.where(["created_at > ?", 1.day.ago] ).each do|item|
    parent_id = item.user.parent_id
    next if notified_user_ids.include?(parent_id)

    parent = User.find(parent_id)
    puts "| check parent #{parent_id} for item #{item.id} | #{notified_user_ids.inspect}"

    # Find approve item message within a day
    notified_user_ids << parent_id
    recent_mail_count = ::NotificationMail.where(["recipient_user_id = ? AND sender_user_id = ? AND related_type = ? AND created_at > ?", parent.id, item.user_id, related_type, 1.day.ago] ).count

    if recent_mail_count > 0
      puts " .. Parent #{parent_id} already has #{recent_mail_count} approval mail recently"
      next
    else
      if parent.email.present?
        ::NotificationMail.create_from_mail(item.user_id, parent.id, UserMailer.check_new_item(item, parent), related_type )
      end
      # Push notification
      note = ::Users::Notifications::ChildNewItem.new(sender_user_id: item.user_id,
        recipient_user_id: parent.id, related_model_type: item.user.class.to_s, related_model_id: item.user_id )
      note.send_push_notification
    end
  end
end

##
# After an item created the after_create immediately generate of notifications but not emails, generate in the
# background.
task :notify_to_approve_items => :environment do
  puts "#############################"
  puts "# Notify to Approve Items"
  puts Time.now.to_s(:db)

  notified_user_ids = Set.new # parent IDs
  ::Item.pending.where(["created_at > ?", 1.day.ago] ).to_a.each do|item|
    item.user.parents.each do|parent|
      puts "| check parent #{parent.id} for item #{item.id} | #{notified_user_ids.inspect}"
      if notified_user_ids.include?(parent.id)
        next
      end
      # Find approve item message within a day
      notified_user_ids << parent.id
      related_type = 'item_for_approval'
      recent_mail_count = ::NotificationMail.where(["recipient_user_id = ? AND sender_user_id = ? AND related_type = ? AND created_at > ?", parent.id, item.user_id, related_type, 1.day.ago] ).count

      if recent_mail_count > 0
        puts " .. Parent #{parent.id} already has #{recent_mail_count} approval mail recently"
        next
      elsif parent.email.present?
        ::NotificationMail.create_from_mail(item.user_id, parent.id, UserMailer.item_for_approval(item, parent), related_type )
        #Add push notification text here.
        if not parent.account_confirmed
          ::Users::Notifications::CheckEmail.create(recipient_user_id: parent.id, sender_user_id: item.user_id)
        end
      end
    end
  end
end
