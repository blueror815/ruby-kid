module Users
  module Notifications
    class TradeChangeMeeting < TradeBasic
      
      def copy_identifier
        :trading_meeting_changed
      end

    end
  end
end