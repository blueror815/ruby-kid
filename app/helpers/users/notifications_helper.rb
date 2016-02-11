module Users
  module NotificationsHelper
  
  def timestamp_ordinal(notification)
    _time = notification.created_at
    time_diff = Time.now - _time
    if time_diff < 1.hour || notification.starred
      I18n.t("time.now")
    elsif time_diff < 1.day
      I18n.t("time.today")
    elsif time_diff < 2.days
      I18n.t("time.yesterday")
    elsif time_diff < 3.days
      I18n.t("time.two_days_ago")
    elsif time_diff < 4.days
      I18n.t("time.three_days_ago")
    else
      _time.strftime('%b %e')
    end
  end

  end
end