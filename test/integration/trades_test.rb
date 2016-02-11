require 'test_helper'
require 'controller_helper'
require 'user_helper'

class TradesTest < ActionDispatch::IntegrationTest

  include ControllerHelper
  include UserHelper

  test "Simple Trade Done by Kids" do
  #def do_test_simple_trade

    build_trade_with_items( [:wii_game_item], [:story_book_item] )

    set_to_accept_trade

    do_test_completed_trade

    @buyer.reload
    assert_equal 1, @buyer.trade_count
    @seller.reload
    assert_equal 1, @seller.trade_count

    ##
    # Trade with 2nd seller

    @selling_parent, @seller = create_parent_and_child(:valid_father, :old_boy)
    @buyer.reload
    logout
    build_trade_with_items( [:nintendo_3ds_game_item], [:lego_train_set] )

    set_to_accept_trade

    do_test_completed_trade

    logout
    login_with(@buyer.user_name, @buyer.password)
    get trades_path(format: 'json')
    h = JSON.parse(response.body)
    assert h.is_a?(Array)
    assert_equal Trading::Trade.where(buyer_id: @buyer.id).count, h.size

    @buyer.reload
    assert_equal 1, @buyer.trade_count
    @seller.reload
    assert_equal 1, @seller.trade_count

    trade_ids = Trading::Trade.where(buyer_id: @buyer.id).all.collect(&:id)
    h.each do|item_h|
      active_trade = item_h['active_trade']
      #if not active_trade.nil? and not active_trade['title'].eql? 'Invite Sent' and not active_trade['title'].eql? 'Past Trade'
      #  assert_nil active_trade
      #end
    end

    puts "====================="

  end

  ##
  # Alpha situation: seller wants more than buyer

  test "Trade Alpha Parent Approval" do
  #def do_test_alpha_trade

    build_trade_with_items( [:wii_system_item], [:story_book_item] )

    @owner_with_parent_approval = @buyer
    @expected_alert_level = 2

    set_to_accept_trade

    do_test_completed_trade

  end

  ##
  # Beta Situation: seller wants a lot less than buyer

  test "Trade Beta Parent Approval" do
  #def do_test_beta_trade

    build_trade_with_items( [:story_book_item, :story_book_item_2], [:wii_game_item_2] )

    @owner_with_parent_approval = @seller

    set_to_accept_trade

    do_test_completed_trade

  end

  test "Trade test types" do
    do_test_trade_types
  end

  test "test trade notification cron job success" do
    build_trade_with_items([:story_book_item], [:wii_system_item])
    @owner_with_parent_approval = @seller
    set_to_accept_trade
    do_test_completed_trade_less_asserts_cron_success
  end

  test "test trade notification cron job failure on day of" do
    build_trade_with_items([:story_book_item], [:wii_system_item])
    @owner_with_parent_approval = @seller
    set_to_accept_trade
    do_test_completed_trade_less_asserts_cron_failure
  end


  def do_test_completed_trade_less_asserts_cron_success
    login_with(@buyer.user_name, @buyer.password)

    pick_meeting_comment = "In front of room 201 before school begins"
    post pick_meeting_path(id: @trade.id, comment: pick_meeting_comment, format: 'json')

    @trade.reload
    last_comment = @trade.trade_comments.last

    logout
    login_with(@seller.user_name, @seller.password)

    post respond_to_meeting_path(id: @trade.id, comment: "I may not make it. Meet later that day.")

    @trade.reload
    last_comment = @trade.trade_comments.last


    logout
    login_with(@buyer.user_name, @buyer.password)
    post respond_to_meeting_path(id: @trade.id, meeting_action: 'agree', comment: "I can make it.")

    @trade.reload

    #assuming that the cron job ran successfully

    assert_equal false, @trade.sent_completed_notification

    Timecop.freeze(DateTime.now + 2.day) do
      ::Trading::Trade.create_message_for_completed_trades
      @trade.reload
      assert_equal false, @trade.sent_completed_notification
    end

    Timecop.freeze(DateTime.now + 4.day + 1.hour) do
      ::Trading::Trade.create_message_for_completed_trades

      @trade.reload

      assert_equal true, @trade.sent_completed_notification
    end

  end

  def do_test_completed_trade_less_asserts_cron_failure
    login_with(@buyer.user_name, @buyer.password)

    pick_meeting_comment = "In front of room 201 before school begins"
    post pick_meeting_path(id: @trade.id, comment: pick_meeting_comment, format: 'json')

    @trade.reload
    last_comment = @trade.trade_comments.last

    logout
    login_with(@seller.user_name, @seller.password)

    post respond_to_meeting_path(id: @trade.id, comment: "I may not make it. Meet later that day.")

    @trade.reload
    last_comment = @trade.trade_comments.last


    logout
    login_with(@buyer.user_name, @buyer.password)
    post respond_to_meeting_path(id: @trade.id, meeting_action: 'agree', comment: "I can make it.")

    @trade.reload

    #assuming that the cron job ran successfully

    assert_equal false, @trade.sent_completed_notification

    #this is to test if the crontab unsuccessfully runs on one day, and then runs the next day successfully
    Timecop.freeze(DateTime.now + 4.day) do
      @trade.reload
      assert_equal false, @trade.sent_completed_notification
    end

    Timecop.freeze(DateTime.now + 5.day) do
      ::Trading::Trade.create_message_for_completed_trades
      @trade.reload
      assert_equal true, @trade.sent_completed_notification
    end

  end

  def do_test_trade_types
    build_trade_with_items([:wii_game_item], [:story_book_item])
    set_to_accept_trade
    notifications = @trade.notifications
    #checking that for the notifications that are sent, their types/trade_id that are within the notificaiton
    #custom data are set correctly
    notifications.each do |notification|
      result_array = notification.test_type_and_trade_id
      assert_equal :trade, result_array[0]
      assert_equal @trade.id, result_array[1]
    end
  end

  ##
  # Items should be restored; notifications cleared out

  #test "Cancel Trade" do
  def do_test_cancel_trade

    build_trade_with_items( [:wii_game_item], [:story_book_item] )

    set_to_accept_trade

    login_with(@seller.user_name, @seller.password)

    puts " --> Seller goes to destroy/end offer"
    delete trade_path(@trade)

    @trade.reload
    assert_equal ::Trading::Trade::Status::ENDED, @trade.status, "Trade status should be ended"

    assert_equal 0, @trade.notifications.sent_to(@seller.id).not_deleted.count, "Seller should not have any more trade related notifications"
    assert_equal 1, @trade.notifications.sent_to(@buyer.id).not_deleted.count, "Buyer should get one last notification"
    assert @trade.notifications.sent_to(@buyer.id).not_deleted.last.is_a?(::Users::Notifications::TradeEnded), "Buyer should get trade ended message"
    assert_equal @trade.id, @trade.notifications.sent_to(@buyer.id).not_deleted.last.get_trade_id
    assert_equal :trade, @trade.notifications.sent_to(@buyer.id).not_deleted.last.get_type

    assert @trade.items.all?{|_item| _item.reload; _item.open? }, "Items of trade should all be restored to open"

  end

  #test "Parent Disapproves Trade" do
  def do_test_disapprove_trade

    build_trade_with_items( [:story_book_item], [:wii_system_item] ) # Beta trade

    logout
    login_with(@selling_parent.user_name, @selling_parent.password)

    puts " --> Seller parent disapproves the trade"
    delete trade_path(@trade)

    @trade.reload
    assert @trade.cancelled?, "Trade status should be cancelled"

    assert_equal 0, @trade.notifications.sent_to(@selling_parent.id).not_deleted.count, "Parent should not have any more trade related notifications"

    assert @trade.notifications.sent_to(@buyer.id).where(sender_user_id: Admin.cubbyshop_admin.id).not_deleted.last.is_a?(::Users::Notifications::TradeParentNotApproved), "Child should get a parent not approved notification"
    assert @trade.notifications.sent_to(@seller.id).not_deleted.last.is_a?(::Users::Notifications::TradeParentNotApproved), "Child should get a parent not approved notification"
    assert_equal :trade, @trade.notifications.sent_to(@buyer.id).where(sender_user_id: Admin.cubbyshop_admin.id).not_deleted.last.get_type
    assert_equal :trade, @trade.notifications.sent_to(@seller.id).not_deleted.last.get_type

    assert @trade.items.all?{|_item| _item.reload; _item.open? }, "Items of trade should all be restored to open"

  end


  ############################

  def setup
    ::NotificationText.populate_from_yaml_file
  end

  private

  ##
  # Build trades based on given Item factory keys for both sides, instead of Trade factory key
  def build_trade_with_items( buyer_items_factory_keys, seller_items_factory_keys)
    ::Items::FavoriteItem.delete_all
    @buying_parent, @buyer = create_parent_and_child(:buying_parent, :buying_child)
    if @selling_parent.nil? && @seller.nil?
      @selling_parent, @seller = create_parent_and_child(:selling_parent, :selling_child)
    end
    puts "Buyer: #{@buyer.user_name}"
    puts "Seller: #{@seller.user_name}"

    ::Users::UserNotificationToken.create(user_id: @buying_parent.id, token:'ij2348dfvjfadsmafsdf98', platform_type:'android')
    ::Users::UserNotificationToken.create(user_id: @buyer.id, token:'ij2348dfvjfadsmafsdf98', platform_type:'android')
    ::Users::UserNotificationToken.create(user_id: @selling_parent.id, token:'k98234afd899mn234243', platform_type:'ios')
    ::Users::UserNotificationToken.create(user_id: @seller.id, token:'k98234afd899mn234243', platform_type:'ios')

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

    puts "Buy adds item to favorites -------------------------"
    put toggle_favorite_item_path(id: one_item.id)
    fav_item = ::Items::FavoriteItem.where(item_id: one_item.id, user_id: @buyer.id)
    assert_not_nil fav_item

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

    # Favorite item
    fav_item = ::Items::FavoriteItem.where(item_id: one_item.id, user_id: @buyer.id).last
    assert_nil fav_item

    assert @trade.waiting_for_counter_offer?, "Trade should be waiting for counter offer"
    assert_equal @seller.id, @trade.waiting_for_user_id
    #assert_equal buyer_real_name, @trade.buyer_real_name
    @trade.save

    assert_equal 1, @trade.notifications.sent_to(@seller.id).in_wait.count, "Notification: seller should have 1"
    assert_equal @trade.id, @trade.notifications.sent_to(@seller.id).in_wait.last.get_trade_id, "Notification should have the same trade_id as the trade"
    assert @trade.notifications.sent_to(@seller.id).all?{|n| n.is_a?(::Users::Notifications::TradeNew) }, "Notification: should be type TradeNew"

    Timecop.freeze(DateTime.now + ::Jobs::NotificationCheck::TIME_LENGTH + 56.hours) do
      first_job = ::Delayed::Job.last
      first_handler = YAML::load(first_job.handler)
      puts " .. #{first_handler} to run_at #{first_job.run_at}"
      assert first_handler.is_a?(::Jobs::NewTradeReminder)
      assert_equal @trade.id, first_handler.notification.get_trade_id, "The reminder should be for trade #{@trade.id}"
      first_handler.perform

      last_job = ::Delayed::Job.last
      last_handler = YAML::load(last_job.handler)
      puts " .. #{last_handler} to run_at #{last_job.run_at}"
      assert last_handler.is_a?(::Jobs::NewTradeReminder)
      assert_equal @trade.id, last_handler.notification.get_trade_id, "The reminder should be for trade #{@trade.id}"
    end

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

    #assert_equal 1, @trade.notifications.sent_to(@buyer.id).count, "Notification: buyer should have 1"
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

    get api_trades_path(format: 'json')
    h = JSON.parse(response.body)
    #h.count will still give the past trades, while the trade_count will not include past trades. BOOM
    #assert_equal @seller.trade_count, h.count

    x = @seller.trade_count
    y = 0
    while y < x do
      result = h[y]['owner']['id'].eql? @seller.id
      assert_equal false, result
      y = y + 1
    end

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
    if @trade.items_of_seller_need_approval? and @trade.items_of_buyer_need_approval?
      assert_equal @trade.waiting_for_user_id, 0
    else
      beta = @trade.who_is_beta
      if beta.eql?(-1) or @trade.items_of_seller_need_approval?
        assert_equal @trade.waiting_for_user_id, @seller.parents.first.id
      elsif beta.eql?(1) or @trade.items_of_buyer_need_approval? && @trade.seller_agree and @trade.buyer_agree
        assert_equal @trade.waiting_for_user_id, @buyer.id
      else
        assert_equal @buyer.id, @trade.waiting_for_user_id
      end
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

  ##
  # Progress further to accept a trade
  def set_to_accept_trade

    @owner_with_parent_approval ||= @buyer

    if  @trade.needs_beta_approval? || @trade.needs_alpha_approval?

      puts "Trade needs parent approval ..."
      @trade.reload
      if @trade.is_buyer_side?(@owner_with_parent_approval)
        assert @trade.fairness_level_comparison > 0, "Trade fairness level should be positive"
        assert_equal @expected_alert_level, @trade.alert_level_comparison, "Alpha-beta alert level should be #{@expected_alert_level}" if @expected_alert_level
      else

        assert @trade.fairness_level_comparison < 0, "Trade fairness level should be negative"
        assert_equal @expected_alert_level, @trade.alert_level_comparison, "Alpha-beta alert level should be #{@expected_alert_level}" if @expected_alert_level
      end

      # Parent getting notification
      @approval_parent = @trade.is_buyer_side?(@owner_with_parent_approval) ? @buying_parent : @selling_parent
      if @trade.needs_alpha_approval?
        do_buyer_accepts_offer

      elsif @trade.needs_beta_approval?
        buyer_notif = @trade.notifications.sent_to(@buyer.id).last
        assert !buyer_notif.is_a?(::Users::Notifications::TradeAccepted), "Since beta approval needed, Buyer should not get TradeAccepted yet"

        # Check for email to parent
        nm = NotificationMail.where(recipient_user_id: @approval_parent.id).last
        assert_not_nil nm
        assert_equal 'trade_approval', nm.related_type
      end
      before_done_notif = @trade.notifications.sent_to(@owner_with_parent_approval.id).not_deleted.last
      #assert before_done_notif.is_a?(::Users::Notifications::TradeParentApprovalNeeded), "The notification to child should be TradeParentApprovalNeeded"

      #test the active_trade_info_for(user, item = nil) method
      #this is with user and without item.
      result = @trade.active_trade_info_for(@owner_with_parent_approval)

      assert result[:trade][:id].eql? @trade.id
      assert_not_nil result

      #this is with user and with item

      parent_notif = ::Users::Notification.sent_to(@approval_parent.id).last
      assert_not_nil parent_notif
      #assert parent_notif.is_a?(::Users::Notifications::TradeParentApproval), "The notification to #{@approval_parent.user_name} parent should be TradeParentApproval"
      #assert_equal @owner_with_parent_approval.id, parent_notif.sender_user_id, "Parent's trade Sender should be #{@owner_with_parent_approval.user_name} (#{@owner_with_parent_approval.id})"
      #assert_equal @trade.id, parent_notif.related_model_id, "Wrong related model ID"
      #assert_equal :trade, parent_notif.get_type
      #assert_equal @trade.id, parent_notif.get_trade_id

      puts "3) Parent approve"
      logout
      login_with(@approval_parent.user_name, @approval_parent.password)
      post accept_trade_path(id: @trade.id, comment: "I agree too", format: 'json')
      @trade.reload

      assert_equal 0, @trade.notifications.sent_to(@approval_parent.id).not_deleted.count, "The approval parent should not still have notification."

      done_deal_notif = @trade.notifications.sent_to(@owner_with_parent_approval.id).not_deleted.last
      #assert done_deal_notif.is_a?(::Users::Notifications::TradeApproved), "The notification to child should be TradeApproved"

      if @trade.needs_beta_approval?
        assert @trade.seller_parent_approve, "After parent approval, seller_parent_approve should be true"
        assert_equal @trade.buyer_id, @trade.waiting_for_user_id, "After seller parent approves, buyer should be the waiting_for_user_id"
        assert !@trade.accepted?, "Trade should not be accepted yet"
        buyer_offer_notif = @trade.notifications.sent_to(@buyer.id).not_deleted.last
        assert buyer_offer_notif.is_a?(::Users::Notifications::TradeReply), "After seller parent approves, buyer should get TradeReply"

        do_buyer_accepts_offer
      end

    else # ================================================
      puts "Trade does not need parent approval ..."

      do_buyer_accepts_offer

      the_other_user = @trade.the_other_user(@buyer)

      before_done_notif = @trade.notifications.sent_to(the_other_user.id).not_deleted.last
      assert before_done_notif.is_a?(::Users::Notifications::TradeAccepted), "The notification to child should be TradeAccepted"

      assert_equal @buyer.id, before_done_notif.sender_user_id, "Buyer's trade notification Sender should be #{@buyer.user_name} (#{@buyer.id})"
      assert before_done_notif.waiting?, "Buyer's offer notification should be WAIT status"
      assert_equal @trade.id, before_done_notif.related_model_id, "Wrong related model ID" # multiple trades

      #assert @trade.notifications.sent_to(@buyer.id).all?{|n| n.is_a?(::Users::Notifications::TradeAccepted) }

    end


    @trade.reload

    puts "------ Trade should be completed after agreements"
    assert @trade.buyer_agree, "Buyer parent approved, so buyer_agree should be true"
    assert @trade.seller_agree, "Seller parent approved, so seller_agree should be true"
    assert @trade.accepted?, "Trade should be accepted status"

    logout

  end

  def do_buyer_accepts_offer
    puts "2) Buyer back to accept offer"
    logout
    login_with(@buyer.user_name, @buyer.password)
    buyer_real_name = 'AcceptingBuyer'
    post accept_trade_path(id: @trade.id, comment: "Good, deal", format: 'json', real_name: buyer_real_name)
    @trade.reload

    assert_equal buyer_real_name, @trade.buyer_real_name
  end


  def do_test_completed_trade

    login_with(@buyer.user_name, @buyer.password)

    get api_trades_path(format: 'json')
    h = JSON.parse(response.body)
    x = @buyer.trade_count
    y = 0
    while y < x do
      result = h[y]['owner']['id'].eql? @buyer.id
      assert_equal false, result
      y = y + 1
    end

    puts "------ Buyer picks meeting"
    pick_meeting_comment = "In front of room 201 before school begins"
    post pick_meeting_path(id: @trade.id, comment: pick_meeting_comment, format: 'json')

    @trade.reload
    assert !@trade.completed?, "Trade without meeting set should not be completed"
    assert @trade.waiting_for_meeting_place?, "Trade should still be waiting for pick of meeting"
    last_comment = @trade.trade_comments.last
    assert_equal @buyer.id, last_comment.user_id, "Sender of trade comment should be buyer"
    assert_equal pick_meeting_comment, last_comment.comment, "Trade comment should be the same: #{pick_meeting_comment}"
    assert_equal @seller.id, @trade.waiting_for_user_id
    assert_equal @buyer.id, @trade.last_meeting_place_set_by

    assert @trade.notifications.sent_to(@seller.id).not_deleted.any?{|n| n.is_a?(::Users::Notifications::TradePickedMeeting) }
    #assert @trade.notifications.sent_to(@buyer.id).not_deleted.any?{|n| n.is_a?(::Users::Notifications::TradePickedMeetingSent) }
    ::Delayed::Job.where(queue: 'user_checks_queue').each{|job| begin; YAML::load(job.handler).perform; rescue; end;  }

    logout
    login_with(@seller.user_name, @seller.password)

    puts "------ Seller disagrees with meeting"
    seller_real_name = 'RespondingSeller'
    post respond_to_meeting_path(id: @trade.id, comment: "I may not make it. Meet later that day.", real_name: seller_real_name)

    put api_trade_completed_path(id: @trade.id, format: 'json', completed: false)
    @trade.reload
    assert_equal false, @trade.completion_confirmed, "Trade should have completion confirmed"

    @trade.reload
    assert !@trade.completed?, "Trade without meeting set should not be completed"
    assert @trade.waiting_for_meeting_place?, "Trade should still be waiting for pick of meeting"
    last_comment = @trade.trade_comments.last
    assert_equal @seller.id, last_comment.user_id, "Sender of trade comment should be seller"
    assert_equal @buyer.id, @trade.waiting_for_user_id
    assert_equal @seller.id, @trade.last_meeting_place_set_by
    assert_equal seller_real_name, @trade.seller_real_name

    #assert @trade.notifications.sent_to(@seller.id).all?{|n| n.is_a?(::Users::Notifications::TradeMeetingChangedSent) }
    assert @trade.notifications.sent_to(@buyer.id).all?{|n| n.is_a?(::Users::Notifications::TradeChangeMeeting) }

    logout
    login_with(@buyer.user_name, @buyer.password)

    puts "------ Buyer agrees with meeting"
    post respond_to_meeting_path(id: @trade.id, meeting_action: 'agree', comment: "I can make it.")

    @trade.reload

    assert @trade.completed?, "Trade should completed after agreed meeting"
    assert !@trade.waiting_for_meeting_place?, "Trade should not be waiting for pick of meeting"

    last_comment = @trade.trade_comments.last
    assert_equal @buyer.id, last_comment.user_id, "Sender of trade comment should be buyer"

    puts "------ Confirm Pack"
    post confirm_packed_path(@trade)

    @trade.reload
    assert @trade.buyer_packed, "Buyer_packed should be set"

    # Trade should only have one notification
    notification_hash = { related_model_type: @trade.class.to_s, related_model_id: @trade.id }

    assert @trade.items.to_a.all?(&:trading?), "All of completed trade's items should be still TRADING"

    #assert_equal 1, ::Users::Notification.where( notification_hash.merge(recipient_user_id: @buyer.id) ).not_deleted.count, "Buyer should have last complete notification"
    #assert_equal 1, ::Users::Notification.where( notification_hash.merge(recipient_user_id: @seller.id) ).not_deleted.count, "Seller should have last complete notification"

    old_buyer_trade_count = @buyer.trade_count
    old_seller_trade_count = @seller.trade_count

    Timecop.freeze(DateTime.now + 4.day + 1.hour) do
      ::Trading::Trade.create_message_for_completed_trades
      @trade.reload
    end
    put api_trade_completed_path(id: @trade.id, format: 'json', completed: true)
    h = JSON.parse(response.body)
    @trade.reload
    #assert h['deleted']
    assert @trade.completion_confirmed, "Trade should have completion confirmed"
    assert @trade.notifications.not_deleted.none?{|n| n.is_a?(::Users::Notifications::TradeCompletedCheck) }, "Should be no more TradeCompletedCheck notification"

    # Check trade count
    #assert_equal (old_buyer_trade_count), @trade.buyer.trade_count, "Buyer's trade count should be incremented"
    #assert_equal (old_seller_trade_count), @trade.seller.trade_count, "Seller's trade count should be incremented"

  end

end
