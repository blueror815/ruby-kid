require 'test_helper'
require 'controller_helper'
require 'user_helper'

class TradesTest < ActionDispatch::IntegrationTest
  include ControllerHelper
  include UserHelper

  test "Simple trade that's denied by buyer" do
    build_trade_with_items([:wii_game_item], [:story_book_item])
    assert_equal @trade.status, "PENDING"

    login_with(@buyer.user_name, @buyer.password)
    to_deny_id = @trade.items_of(@trade.seller_id).first.id
    post cancel_trade_path(id: @trade.id, continue: true)

    @trade.reload
    assert_equal @trade.denied, [to_deny_id]
    assert_equal @trade.items.count, 1
    #if it's still pending then you can decline the offer at this point and it should go to teh denied thing.
  end

  def build_trade_with_items( buyer_items_factory_keys, seller_items_factory_keys)
    @buying_parent, @buyer = create_parent_and_child(:buying_parent, :buying_child)
    @selling_parent, @seller = create_parent_and_child(:selling_parent, :selling_child)
    puts "Buyer: #{@buyer.user_name}"
    puts "Seller: #{@seller.user_name}"

    buyer_items = buyer_items_factory_keys.collect do |factory_k|
      _item = build(factory_k, :activated)
      _item.user = @buyer
      _item.save
      _item
    end
    seller_items = seller_items_factory_keys.collect do |factory_k|
      _item = build(factory_k, :activated)
      _item.user = @seller
      _item.save
      _item
    end

    login_with(@buying_parent.user_name, @buying_parent.password)

    get api_parent_child_dashboard_path(child_id: @buyer.id, format: 'json')

    #going to test trying to get another child's user dashboard, should return 0 items.
    get api_parent_child_dashboard_path(child_id: @seller.id, format: 'json')
    assert_response 403
    logout

    login_with(@buyer.user_name, @buyer.password)

    # Buyer views item
    one_item = seller_items.last
    get item_path(one_item)
    assert_response :success
    assert response.body.index(one_item.description), "There should be one created item shown w/ description #{one_item.description}"

    # Invite to trade
    one_offer_attr = attributes_for(:trade_only_question)
    buyer_real_name = 'RealBuyer'
    seller_real_name = 'RealSeller'
    post_via_redirect create_trade_path(item_id: one_item.id, comment: one_offer_attr[:comment], format: 'json', skip_eligibility_check: true, real_name: buyer_real_name)

    get trade_path(id: 123123123, format: 'json')
    assert_response 404

    @trade = ::Trading::Trade.where(seller_id: one_item.user_id, buyer_id: @buyer.id).active.last
    get trade_path(id: @trade.id, format: 'json')
    h = JSON.parse(response.body)
    assert h['merchant']['items'][0]['id'].eql? one_item.id


    assert_not_nil @trade
    puts "-------- Now trade has items #{@trade.items.collect(&:id)}"
    assert_equal 1, @trade.items.count, "Trade should have one item"
    assert_not_nil @trade.items.find { |_item| _item.id == one_item.id }, "Trade should have the item #{one_item.title}"
    assert_equal [one_item.id], @trade.items_of(@seller).collect(&:id), "Trade should have items of #{@seller.user_name}"
    assert_not_nil @trade.trade_comments.find {|_comment| _comment.comment == one_offer_attr[:comment] }, "Trade should have the trade comment"

    assert @trade.waiting_for_counter_offer?, "Trade should be waiting for counter offer"
    assert_equal @seller.id, @trade.waiting_for_user_id
    #assert_equal buyer_real_name, @trade.buyer_real_name
    @trade.save

    assert_equal 1, @trade.notifications.sent_to(@seller.id).in_wait.count, "Notification: seller should have 1"
    assert_equal @trade.id, @trade.notifications.sent_to(@seller.id).in_wait.last.get_trade_id, "Notification should have the same trade_id as the trade"
    assert @trade.notifications.sent_to(@seller.id).all?{|n| n.is_a?(::Users::Notifications::TradeNew) }, "Notification: should be type TradeNew"
    assert_equal 1, @trade.notifications.sent_to(@buyer.id).count, "Notification: buyer should have 1"
    assert_equal @trade.id, @trade.notifications.sent_to(@buyer.id).last.get_trade_id, "Notification should have the same trade_id as the trade"
    assert @trade.notifications.sent_to( @buyer.id).all?{|n| n.is_a?(::Users::Notifications::TradeNew) }, "Notification: should be type TradeNew"

    # Add comment
    second_comment = "User #{@buyer.user_name} has more comment"
    post create_trade_comments_path(id: @trade.id, comment: second_comment)
    @trade.reload
    assert_not_nil @trade.trade_comments.find {|_comment| _comment.comment == second_comment }, "Trade should have the 2nd trade comment"
    assert_equal @seller.id, @trade.waiting_for_user_id
    seller_notes = @trade.notifications.not_deleted.sent_to(@seller.id).to_a
    assert_equal 1, seller_notes.size, "There should be 1, ONLY 1, notification waiting for seller action"
    assert seller_notes.first.starred, "That notification for seller should be starred"
    assert seller_notes.first.additional_action_taken, "That notification for seller should have 'additional_action_taken'"

    assert_equal 1, @trade.notifications.sent_to(@buyer.id).count, "Notification: buyer should have 1"
    assert @trade.notifications.sent_to(@buyer.id).all?{|n| n.is_a?(::Users::Notifications::TradeNew) }, "Notification: should be type TradeNew"

    # Get Trade - check JSON
    get "#{trade_path(@trade)}.json"
    json_h = JSON.parse(response.body)
    assert_equal 'OPEN', json_h['status']
    assert json_h['customer'].present?
    assert json_h['customer']['user'].present?
    assert_equal @buyer.id, json_h['customer']['user']['id'], "JSON response should have customer w/ ID #{@buyer.id}"
    assert json_h['merchant'].present?
    assert json_h['merchant']['user'].present?
    assert_equal @seller.id, json_h['merchant']['user']['id'], "JSON response should have merchant w/ ID #{@seller.id}"
    if ::Item.owned_by(@buyer).open_items.count < ::Trading::Trade::ITEMS_MIN_THRESHOLD
      assert_equal false, json_h['success'], "JSON response should have success false"
      assert_equal false, json_h['is_eligible'], "JSON response should have is_eligible false"
    end

    # Notification check
    seller_notif = ::Users::Notification.sent_to(@seller.id).last # limit(2).order('id desc').to_a[1]
    assert_not_nil seller_notif
    assert seller_notif.is_a?(::Users::Notifications::TradeNew), "The notification to seller should be TradeNew"
    assert_equal @buyer.id, seller_notif.sender_user_id, "Seller's trade notification Sender should be #{@buyer.user_name} (#{@buyer.id})"
    assert seller_notif.waiting?, "Seller's offer notification should be WAIT status"
    assert_equal @trade.id, seller_notif.related_model_id, "Wrong related model ID"

    logout

    # Seller login

    login_with(@seller.user_name, @seller.password)

    get notification_path(seller_notif)
    seller_notif.reload
    assert seller_notif.waiting?, "Seller's notification of Trade Invitation should stay at wait after view but no reply"

    # Reply to comment
    puts "--------- Now seller replies question"
    second_reply = "The merchant has your answer"
    post create_trade_comments_path(id: @trade.id, comment: second_reply )
    @trade.reload
    assert_not_nil @trade.trade_comments.find {|_comment| _comment.comment == second_reply }, "Trade should have the 2nd trade comment reply"
    buyer_reply_notif = ::Users::Notifications::TradeReply.sent_to(@buyer.id ).last
    assert_not_nil buyer_reply_notif, "There should be a TradeReply notification sent to question-maker that question is answered."
    assert_equal @seller.id, buyer_reply_notif.sender_user_id

    # Add more to trade
    put reply_trade_path(id: @trade.id, item_id: buyer_items.collect(&:id), comment: 'Adding more items!', format: 'json', real_name: seller_real_name)
    @trade.reload
    puts "-------- Now trade has items #{@trade.items.collect(&:id)}"

    assert_equal [one_item.id], @trade.items_of(@seller).collect(&:id), "Trade should STILL have items of #{@seller.user_name}"
    assert_equal buyer_items.collect(&:id), @trade.items_of(@buyer).collect(&:id), "Trade should have items of #{@buyer.user_name}"

    assert !@trade.waiting_for_counter_offer?, "Trade should have enough items, not waiting for counter offer"
    if @trade.needs_parent_approval? && @trade.needs_beta_approval?
      assert_equal @seller.id, @trade.waiting_for_user_id, "Beta trade should have seller being waiting_for_user_id"
    else
      assert_equal @buyer.id, @trade.waiting_for_user_id, "Trade should have buyer being waiting_for_user_id"
    end
    assert_equal seller_real_name, @trade.seller_real_name

    # Check item status
    puts "------ Items in trade should be held"
    assert @trade.waiting_for_meeting_place?, "Should be waiting for meeting place"
    assert @trade.items.all?{|_item| _item.reload; _item.trading? }, "Both sides' items in agreed-trade should have status changed"

    # Check JSON again to ensure customer stays same
    json_h = JSON.parse(response.body)
    trade_h = json_h['trade']
    assert trade_h.present?
    assert trade_h['customer'].present?
    assert trade_h['customer']['user'].present?
    assert_equal @buyer.id, trade_h['customer']['user']['id'], "JSON response should have customer w/ ID #{@buyer.id}"
    assert trade_h['merchant'].present?
    assert trade_h['merchant']['user'].present?
    assert @trade.denied.empty?
    assert_equal @seller.id, trade_h['merchant']['user']['id'], "JSON response should have merchant w/ ID #{@seller.id}"

    logout

    puts "--------------------"
  end

end
