require 'test_helper'
require 'controller_helper'
require 'user_helper'
require 'integration/helpers/seller_helper'

class BuyRequestsTest < ActionDispatch::IntegrationTest

  include ControllerHelper
  include UserHelper
  include ::Integration::Helpers::SellerHelper

  test "Parent Accepts Buy Request" do
    buy_request = build_buy_request

    puts "---------------- Parent accept the buy request"
    login_with(@buying_parent.user_name, @buying_parent.password)

    put_via_redirect accept_buy_request_path(id: buy_request.id, buy_request:{ parent_message: 'Blah blah', name:'Test User', email:"testuser@hotmail.com"} )
    buy_request.reload
    assert buy_request.waiting_for_sell?
    assert buy_request.items.all?{|item| item.buying? }, "All items should be set with BUYING status"

    notifications = ::Users::Notification.where(recipient_user_id: @buying_parent.id, related_model_type:'Trading::BuyRequest', related_model_id:buy_request.id).all
    assert notifications.all?{|n| n.deleted? }

    logout
    puts "---------------- Seller responds"
    login_with(@seller.user_name, @seller.password)

    put_via_redirect not_sold_buy_request_path(id: buy_request.id)
    buy_request.reload
    assert buy_request.waiting_for_sell?
    assert buy_request.items.all?{|item| item.buying? }, "All items should be set with BUYING status"

    put_via_redirect sold_buy_request_path(id: buy_request.id)
    buy_request.reload
    assert buy_request.sold?
    assert buy_request.items.all?{|item| item.ended? }, "All items should be set with ENDED status"

    puts "====================="

  end

  test "Parent Declines Buy Request" do
    buy_request = build_buy_request

    puts "---------------- Parent decline the buy request"
    login_with(@buying_parent.user_name, @buying_parent.password)

    put_via_redirect decline_buy_request_path(item_ids: buy_request.items.collect(&:id) ) # (id: buy_request.id)
    buy_request.reload
    assert buy_request.declined?
    assert buy_request.items.all?{|item| item.open? }, "All items should be restored to OPEN status"

    notifications = ::Users::Notification.where(recipient_user_id: @buying_parent.id, related_model_type:'Trading::BuyRequest', related_model_id:buy_request.id).all
    assert notifications.all?{|n| n.deleted? }

    puts "====================="
  end

  ################################

  protected

  def build_buy_request

    seller_items = build_user_items( @seller, [:wii_game_item, :nintendo_3ds_game_item] )
    seller_items.each{|item| item.activate! }

    login_with(@buyer.user_name, @buyer.password)

    one_item = seller_items.last
    get item_path(one_item)
    assert_response 200
    post api_carts_add_path(format:'json', item_id: one_item.id)
    
    cart = ::Carts::Cart.new(@buyer)
    seller_cart_items = cart.sellers_items_map[one_item.user_id]
    assert seller_cart_items.present?
    assert seller_cart_items.collect(&:item_id).include?(one_item.id)

    post_via_redirect buy_requests_path(item_id: one_item.id, message: 'Hello daddy I want this' )
    buy_request = ::Trading::BuyRequest.where(buyer_id: @buyer.id).last
    assert buy_request.items.collect(&:id).include?(one_item.id)
    
    notification = ::Users::Notifications::NewBuyRequest.where(recipient_user_id: @buying_parent.id).last
    assert_equal @buyer.id, notification.sender_user_id
    assert_equal buy_request.id, notification.related_model_id

    logout

    buy_request
  end


  def setup

    @buying_parent, @buyer = create_parent_and_child(:buying_parent, :buying_child)
    @selling_parent, @seller = create_parent_and_child(:selling_parent, :selling_child)
    puts "Buyer: #{@buyer.user_name}"
    puts "Seller: #{@seller.user_name}"

  end

end
