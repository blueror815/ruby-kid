require 'test_helper'
require 'controller_helper'
require 'user_helper'

class NotificationTextTest < ActionDispatch::IntegrationTest

	include UserHelper
	include ControllerHelper

	test "check if notification texts are called correctly" do
		build_trade_with_items([:story_book_item], [:wii_system_item])
		notifications = @trade.notifications
		assert_equal('trading_new_trade_from_customer', notifications[0].copy_identifier.to_s)
		#assert_equal('trading_new_trade_from_merchant', notifications[1].copy_identifier.to_s)

		assert_equal('Wants to Trade!', notifications[0].title)
		#assert_equal('Invite Sent', notifications[1].title)
  end


  def setup
    NotificationText.populate_from_data_file
  end
end
