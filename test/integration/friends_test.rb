require 'test_helper'
require 'controller_helper'
require 'user_helper'

class FriendsTest < ActionDispatch::IntegrationTest

  include ControllerHelper
  include UserHelper

  test 'Test Add Friend Path Version 1: Both Approve' do
    setup_initial_friend_request(1)

    testing_for_api_version(1)
  end

  test 'Test Add Friend Path Version 2: Not Requires Parent Approval' do
    setup_initial_friend_request(2)

    testing_for_api_version(2)
  end

  test "Add Friend Path First Approve second dissaprove" do

  end

  test "Add Friend Path First Dissaprove" do

  end

  # General users & friends wipe out.
  def setup
    ::User.all.each{|u| u.destroy }
    ::Users::FriendRequest.delete_all
    ::Users::UserNotificationToken.delete_all
  end

  protected

  ##
  # At end, @parent_1 is current logged-in user.
  def setup_initial_friend_request(api_version = 2)
    @api_version = api_version



    @parent_1, @child_1 = create_parent_and_child(:buying_parent, :buying_child) #macy
    @parent_2, @child_2 = create_parent_and_child(:selling_parent, :selling_child) #kelly

    ::NotificationText.populate_from_yaml_file
    if Rpush::Gcm::App.count == 0
      Rpush::Gcm::App.create( "name"=>"KidsTrade_android", "environment"=>nil, "certificate"=>nil, "password"=>nil, "connections"=>1, "auth_key"=>"AIzaSyClYB5FHXUA6CdC3YFXn29UzV9tPgRiC7I" )
    end
    ::Users::UserNotificationToken.create(user_id: @parent_2.id, token:'ij2348dfvjfadsmafsdf98', platform_type:'android')
    ::Users::UserNotificationToken.create(user_id: @child_2.id, token:'ij2348dfvjfadsmafsdf98', platform_type:'android')
    ::Users::UserNotificationToken.create(user_id: @parent_1.id, token:'k98234afd899mn234243', platform_type:'ios')
    ::Users::UserNotificationToken.create(user_id: @child_1.id, token:'k98234afd899mn234243', platform_type:'ios')

    @friend_request = ::Users::FriendRequest.where(recipient_user_id: @child_2.id, requester_user_id: @child_1.id).last
    assert_nil @friend_request
    first_message = "Let's be friends"

    puts "Child 1 #{@child_1.user_name} creates Friend Request to add #{@child_2.user_name} ----------------"
    login_with(@child_1.user_name, @child_1.password)
    post_via_redirect create_friend_request_path(requested: @child_2.id, message: first_message, api_version: @api_version)

    @friend_request = ::Users::FriendRequest.where(recipient_user_id: @child_2.id, requester_user_id: @child_1.id).last
    assert_not_nil @friend_request
    assert_equal @parent_1.id, @friend_request.requester_parent_id
    assert_equal first_message, @friend_request.requester_message

    if @api_version == 1

      assert_equal :sent_request_parent, @friend_request.status, 'Status of friend request should be sent_request_parent'

      parent_1_n = ::Users::Notification.where(recipient_user_id: @child_1.parent_id, sender_user_id: @child_1.id).last
      assert parent_1_n.is_a?(::Users::Notifications::KidAddFriendToParent)
      nm_1 = ::NotificationMail.last
      assert_not_nil nm_1
      puts " -> Child 1 to parent: NM #{nm_1.id}"
      assert_equal 'friend_request', nm_1.related_type
      assert_equal @friend_request.id, nm_1.related_type_id
      assert_equal @child_1.id, nm_1.sender_user_id
      assert_equal @child_1.parent_id, nm_1.recipient_user_id

      # Check reminder job
      last_job = ::Delayed::Job.last
      handler = YAML::load(last_job.handler)
      assert handler.is_a?(::Jobs::ApproveFriendRequestReminder), "There should have a ApproveFriendRequestReminder for parent #{@parent_1.user_name}"

      Timecop.freeze(nm_1.created_at + ::Jobs::UserCheck::TIME_LENGTH + 5.hours) do
        handler.perform
        another_nm = ::NotificationMail.last
        assert_not_nil another_nm
        assert_equal 'friend_request', another_nm.related_type
        assert_equal  @friend_request.id, another_nm.related_type_id
      end

      puts "#{@parent_1.user_name} views add friend approval #{@child_2.user_name} ----------------"
      logout
      login_with(@parent_1.user_name, @parent_1.password)


    else # Child only
      assert_equal :sent_recip_child, @friend_request.status, 'Status of friend request should be sent_request_child'

      parent_1_n_count = ::Users::Notifications::KidAddFriendToParent.where(recipient_user_id: @child_1.parent_id, sender_user_id: @child_1.id).count
      assert_equal 0, parent_1_n_count, 'Without parent approval, parent should not get notification'

      nm_count = NotificationMail.where(related_type: 'friend_request', related_type_id: @friend_request.id).count
      assert_equal 0, nm_count, 'Without parent approval, parent should not get notification mail'

    end
  end


  def testing_for_api_version(api_version)

    if api_version == 1
      puts "Parent 1 #{@parent_1.user_name} approves adding #{@child_2.user_name} ----------------"
      put_via_redirect accept_friend_request_path(id: @friend_request.id, message:'I accept', api_version: api_version)

      @friend_request.reload
      assert_equal :sent_recip_child, @friend_request.status

      assert_equal 0, ::Users::Notifications::KidAddFriendToParent.where(recipient_user_id: @parent_1.id, sender_user_id: @child_1.id).count, 'KidAddFriendToParent should be deleted after accept'

      # Check push notification
      push_note = ::Rpush::Gcm::Notification.last
      assert_not_nil push_note
    end

    child_2_n = ::Users::Notification.where(recipient_user_id: @child_2.id, sender_user_id: @child_1.id).last
    assert child_2_n.is_a?(::Users::Notifications::KidAddFriendToKid)
    #assert child_2_n.text_for_push_notification.present? # really depends update to date NotificationText


    puts "Child 2 #{@child_2.user_name} approves also ------------------"
    logout
    login_with(@child_2.user_name, @child_2.password)
    if api_version == 2
      get friend_request_path(id: @friend_request.id, api_version: api_version, format:'json')
      json_to_child_2 = JSON.parse(response.body)
      assert @friend_request.requester_message, json_to_child_2['message']
    end

    put_via_redirect accept_friend_request_path(id: @friend_request.id, message:'I accept', api_version: api_version)

    @friend_request.reload

    if api_version == 1
      assert_equal :accept_recip_child, @friend_request.status

      assert_equal 0, ::Users::Notifications::KidAddFriendToKid.where(recipient_user_id: @child_2.id, sender_user_id: @child_1.id).count, 'KidAddFriendToKid should be deleted after accept'

      parent_2_n = ::Users::Notification.where(recipient_user_id: @parent_2.id, sender_user_id: @child_2.id).last
      assert_not_nil parent_2_n
      assert parent_2_n.is_a?(::Users::Notifications::KidAddFriendToParent)

      nm_2 = ::NotificationMail.last
      assert_not_nil nm_2

      puts " -> Child 2 to parent: NM #{nm_2.id}"
      assert_equal 'friend_request', nm_2.related_type
      assert_equal @friend_request.id, nm_2.related_type_id
      assert_equal @child_2.id, nm_2.sender_user_id
      assert_equal @child_2.parent_id, nm_2.recipient_user_id

      puts "Parent 2 #{@parent_2.user_name} approves also ------------------"
      logout
      login_with(@parent_2.user_name, @parent_2.password)

      put_via_redirect accept_friend_request_path(id: @friend_request.id, message:'I accept', api_version: api_version)

    end

    @friend_request.reload
    assert_equal :accepted_full, @friend_request.status

    assert_equal 0, ::Users::Notifications::KidAddFriendToParent.where(recipient_user_id: @parent_2.id, sender_user_id: @child_2.id).count, 'KidAddFriendToParent to parent 2 should be deleted after accept'

    friend_note_1 = ::Users::Notification.where(recipient_user_id: @child_2.id).last
    friend_note_2 = ::Users::Notification.where(recipient_user_id: @child_1.id).last

    assert friend_note_1.is_a?(::Users::Notifications::ChildIsNowFriend)
    assert_equal @child_1.id, friend_note_1.sender_user_id
    assert friend_note_2.is_a?(::Users::Notifications::ChildIsNowFriend)
    assert_equal @child_2.id, friend_note_2.sender_user_id

  end

end
