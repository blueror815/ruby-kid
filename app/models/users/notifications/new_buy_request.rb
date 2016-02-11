module Users
  module Notifications
    class NewBuyRequest < ::Users::Notification
      
      
      def copy_identifier
        :new_buy_request
      end
      
    end
  end
end
