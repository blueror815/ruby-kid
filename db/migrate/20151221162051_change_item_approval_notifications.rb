class ChangeItemApprovalNotifications < ActiveRecord::Migration
  def up
    now_id = :parenting_check_new_item
    ::NotificationText.where(identifier: now_id ).delete_all

    ::NotificationText.create(identifier: now_id, language:'en',
                                non_tech_description: 'New item without parent approval required',
                                title: 'Posted New Items', subtitle:"Check 'em out!", push_notification: 'Posted New Items' )
  end

  def down
  end
end
