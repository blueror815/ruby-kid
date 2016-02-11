module NotificationHandler
  
  ##
  # @return <Array of ActiveRecord>
  def find_related_notifications
    ::Users::Notification.where(related_model_type: self.class.to_s, related_model_id: self.id)
  end
  
  def remove_related_notifications!
    find_related_notifications.destroy_all
  end
  
  def mark_notifications_as_viewed
    find_related_notifications.update_all(status: ::Users::Notification::Status::VIEWED)
  end
  
end