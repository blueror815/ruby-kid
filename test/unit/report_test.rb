require 'test_helper'
require 'user_helper'
require 'item_helper'

class ReportTest < ActiveSupport::TestCase

  include UserHelper
  include ItemHelper

  test "Reported Non-New User" do
    make_test_on_seller(@friend, false)
  end

  test "Reported New User" do

    seller = create(:old_girl)
    make_test_on_seller(seller, true)
  end

  protected

  def make_test_on_seller(seller, make_new_user)

    seller.reload

    # 1st item
    item = Item.new( attributes_for(:item_with_category_id) )
    item.user_id = seller.id
    item.save
    photo_attr = attributes_for(:photo_ff13)
    file_data = load_photo_file_data(photo_attr[:image])
    item.load_item_photos_with_params( item_photos: [file_data] )

    # 2nd item
    second_item = Item.new( attributes_for(:item_with_top_category) )
    second_item.user_id = seller.id
    second_item.save
    photo_attr = attributes_for(:photo_ff13)
    file_data = load_photo_file_data(photo_attr[:image])
    second_item.load_item_photos_with_params( item_photos: [file_data] )

    Item.owned_by(seller).each{|_item| _item.activate! }

    if make_new_user

      seller.reload
      assert seller.new_user?

    else
      # This way can make up the non-new seller again cuz after item posting stats would change
      seller.item_count = User::MINIMUM_ITEM_COUNT_BEYOND_NEW
      seller.trade_count = 1
      seller.save
      seller.reload
      assert !seller.new_user?
    end

    puts "---- Create report"
    report = ::Report.new(content_type: 'Item', content_type_id: item.id, offender_user_id: item.user_id, reason_type:'BAD_WORDS')
    report.reporter_user_id = @buyer.id
    report.created_at = 4.days.ago
    report.save
    report.reload

    notification = Users::Notification.where(recipient_user_id: seller.parent.id, related_model_type: 'Report', related_model_id: report.id).first
    if seller.new_user?
      assert_nil notification
      assert Item.owned_by(seller).all?{|_item| _item.suspended? }, "All items of new user should be suspended"

      assert report.pending_admin_action?, "This report should be escalated to PENDING_ADMIN_ACTION cuz of new user"

    else

      item.reload
      assert item.suspended?

      assert_not_nil notification
      assert notification.is_a?(::Users::Notifications::ChildReported)
      user_mail = NotificationMail.where(recipient_user_id: seller.parent.id, related_type: 'child_reported').last
      assert_not_nil user_mail

      # Who should be the sender?

      assert report.pending_parent_action?, "This report should be PENDING_PARENT_ACTION"

    end

    #reported_a_child_n = Users::Notification.where(recipient_user_id: report.reporter.parent_id, related_model_type: 'Report', related_model_id: report.id ).last
    #assert_not_nil reported_a_child_n
    #assert_equal @buyer.id, reported_a_child_n.sender_user_id, "Sender of Reported a Child msg should be the reporting child"

    #reported_a_child_n = Users::Notification.where(recipient_user_id: report.reporter.parent_id, related_model_type: 'Report', related_model_id: report.id ).last
    #assert_not_nil reported_a_child_n
    #assert_equal @buyer.id, reported_a_child_n.sender_user_id, "Sender of Reported a Child msg should be the reporting child"

    # Run to run blocks
    ::Report.review_pending_reports

    report.reload

    if (family_users = @buyer.family_users).present?
      @buyer.reload
      family_users.each do|user|
        assert user.boundaries.user_blocks.present?
        assert user.boundaries.user_blocks.collect(&:object_user_id).include?(seller.id)
      end
    end
    if (family_users = seller.family_users).present?
      seller.reload
      family_users.each do|user|
        assert user.boundaries.present?
        assert user.boundaries.user_blocks.collect(&:object_user_id).include?(@buyer.id)
      end
    end

    puts "================================"
  end

    # Run to run blocks
    ::Report.review_pending_reports

  protected

  def setup
    User.delete_all

    @buyer = create(:tiger_child)
    @buyer.reload

    @friend = create(:tiger_child_classmate)
    @friend.current_school_id = @buyer.current_school_id
    @friend.save
    @friend.update_school_group!(grade: @buyer.grade, teacher: @buyer.teacher)

    @friend.reload

  end

end
