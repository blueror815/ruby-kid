##
# Default type.
module Users
  module Notifications
    class Basic < ::Users::Notification

      def copy_identifier
      	:trade_basic
      end

      def get_type
      	:social
      end

    end
  end
end
