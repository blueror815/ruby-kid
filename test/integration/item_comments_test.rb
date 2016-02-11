require 'test_helper'
require 'controller_helper'
require 'user_helper'
require 'item_helper'

class ItemCommentsTest < ActionDispatch::IntegrationTest

  include ControllerHelper
  include UserHelper
  include ItemHelper

  def test_create_and_reply_item_comments
    parent, child = create_parent_and_child(:tiger_parent, :tiger_child, 'FATHER')
    login_with(child.user_name, child.password)

    item = build(:wii_game_item)
    item.user_id = child.id
    item.save

    last_item = Item.where(user_id: child.id).last
    assert_not_nil last_item

    logout
    ##########################

    viewer_parent, viewer = create_parent_and_child(:chicken_parent, :chicken_child, 'MOTHER')
    login_with(viewer.user_name, viewer.password)

    first_comment_body = 'Is this game new or used?'
    post 'item_comments', item_comment: {item_id: last_item.id, body: first_comment_body}
    last_comment = ::ItemComment.where(item_id: last_item.id, user_id: viewer.id).last
    assert_not_nil last_comment
    assert_equal first_comment_body, last_comment.body
    assert_equal viewer.id, last_comment.buyer_id
    assert_equal child.id, last_comment.recipient_user_id, "Recipient of ItemComment should be #{child.user_name} (#{child.id}"

    last_note = ::Users::Notification.last
    assert_not_nil last_note
    assert_equal :has_comment, last_note.get_type
    assert_equal last_comment.user_id, last_note.sender_user_id
    assert_equal last_comment.recipient_user_id, last_note.recipient_user_id

    logout

    ##########################

    login_with(child.user_name, child.password)
    second_comment_body = "It is used but working for play still"
    post 'item_comments', item_comment: {item_id: last_item.id, body: second_comment_body, parent_id: last_comment.id}
    second_comment = ::ItemComment.where(item_id: last_item.id, user_id: child.id).last
    assert_equal last_comment.id, second_comment.parent_id
    assert_equal second_comment_body, second_comment.body
    assert_equal viewer.id, second_comment.buyer_id
    assert_equal viewer.id, second_comment.recipient_user_id, "Recipient of ItemComment should be #{viewer.user_name} (#{viewer.id})"

    second_note = ::Users::Notification.last
    assert_equal second_comment.sender_user_id, second_note.sender_user_id
    assert_equal :has_answer, second_note.get_type
    assert_equal second_comment.recipient_user_id, second_note.recipient_user_id

    logout

    ##########################
    login_with(viewer.user_name, viewer.password)

    another_comment_body = 'No scratches on disc?'
    post 'item_comments', item_comment: {item_id: last_item.id, body: another_comment_body, parent_id: second_comment.id}
    another_comment = ::ItemComment.where(item_id: last_item.id, user_id: viewer).last
    assert_not_nil another_comment
    assert_equal another_comment_body, another_comment.body
    assert_equal viewer.id, another_comment.buyer_id
    assert_equal child.id, another_comment.recipient_user_id, "Recipient of ItemComment should be #{child.user_name} (#{child.id}"

    another_note = ::Users::Notification.last
    assert_equal another_comment.sender_user_id, another_note.sender_user_id
    assert_equal :has_comment, another_note.get_type
    assert_equal another_comment.recipient_user_id, another_note.recipient_user_id

  end


end