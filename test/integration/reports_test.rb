require 'test_helper'
require 'controller_helper'
require 'user_helper'
require 'item_helper'

class ReportsTest < ActionDispatch::IntegrationTest

  include ControllerHelper
  include UserHelper
  include ItemHelper

  test "Report Item" do

    logout
    login_with(@second_child.user_name, @second_child.password)

    first_item = Item.open_items.where(user_id: @first_child.id).first
    second_item = Item.open_items.where(user_id: @first_child.id).last
    reason_type = 'BEING_MEAN'
    second_reason_type = 'BAD_WORDS'
    post reports_path( reason_type: reason_type, reason_message: 'This seller has mean listing', item_id: first_item.id )
    first_report = Report.where(reporter_user_id: @second_child.id).last

    assert first_report.pending_parent_action?
    assert_equal @second_child.id, first_report.reporter_user_id
    assert_equal @first_child.id, first_report.offender_user_id
    assert_equal reason_type, first_report.reason_type
    assert_equal 'ITEM', first_report.content_type
    assert_equal first_item.id, first_report.content_type_id
    assert first_report.content_record.is_a?(Item)
    assert_equal ::Item::Status::REPORT_SUSPENDED, first_report.content_record.status

    # Notifications
    notification = Users::Notification.where(recipient_user_id: @first_parent.id, related_model_type: 'Report', related_model_id: first_report.id).first
    assert_not_nil notification
    assert notification.is_a?(::Users::Notifications::ChildReported)
    if @first_child.new_user?
      assert Item.owned_by(@first_child).all?{|_item| _item.suspended? }, "All items of new user should be suspended"
      assert first_report.pending_admin_action?, "This report should be escalated to PENDING_ADMIN_ACTION cuz of new user"

    else
      # Who should be the sender?
      assert first_report.pending_parent_action?, "This report should be PENDING_PARENT_ACTION"
    end

    #reported_note = Users::Notification.where(recipient_user_id: @second_parent.id, related_model_type: 'Report', related_model_id: first_report.id).first
    #assert reported_note.is_a?(::Users::Notifications::ReportedChild)

    # check permissions
    assert first_report.viewable_by_user?(@first_child)
    assert first_report.viewable_by_user?(@first_parent)
    assert first_report.viewable_by_user?(@second_child)
    assert first_report.viewable_by_user?(@second_parent)

    assert !first_report.repostable_by_user?(@first_child)
    assert first_report.repostable_by_user?(@first_parent)
    assert !first_report.repostable_by_user?(@second_child)
    assert !first_report.repostable_by_user?(@second_parent)

    # Check user blocks
    @second_child.reload
    assert_not_nil @second_child.boundaries.user_blocks.find{|ub| ub.content_type_id == @first_child.id }, "The seller should be ON reporter's block list"
    assert_equal 1, @second_child.reporter_count
    @first_child.reload
    assert_equal 1, @first_child.reported_count

    # 2nd Report
    post reports_path( report:{reason_type: second_reason_type, reason_message: 'Should delete this item'}, item_id: second_item.id )
    second_report = Report.where(reporter_user_id: @second_child.id).last

    assert second_report.pending_parent_action?
    assert_equal @second_child.id, second_report.reporter_user_id
    assert_equal @first_child.id, second_report.offender_user_id
    assert_equal second_reason_type, second_report.reason_type
    assert_equal 'ITEM', second_report.content_type
    assert_equal second_item.id, second_report.content_type_id
    assert second_report.content_record.is_a?(Item)
    assert_equal ::Item::Status::REPORT_SUSPENDED, second_report.content_record.status

    @second_child.reload
    assert_equal 2, @second_child.reporter_count
    @first_child.reload
    assert_equal 2, @first_child.reported_count

    logout
    login_with(@first_child.user_name, @first_parent.password)
    post_via_redirect report_repost_path(id: first_report.id, format: 'json')
    json_h = JSON.parse(response.body)
    assert !json_h['success'], "Child's attempt to repost item should fail"

    first_report.reload
    first_item.reload
    assert first_report.content_record.is_a?(Item)
    assert_equal ::Item::Status::REPORT_SUSPENDED, first_report.content_record.status
    assert first_report.pending_parent_action?, "Child cannot repost the item"

    puts "---- Parent reposting"
    logout
    login_with(@first_parent.user_name, @first_parent.password)

    get report_path(id: first_report.id, format: 'json')
    json_h = JSON.parse(response.body)
    assert json_h.keys.include?('offender')
    assert json_h.keys.include?('reporter')
    assert json_h.keys.include?('item')

    post report_repost_path(id: first_report.id, format: 'json')

    first_report.reload
    first_item.reload
    assert first_report.pending_repost_approval?
    assert_equal ::Item::Status::REPORT_SUSPENDED, first_report.content_record.status

    puts "---- Moderator approving"
    logout
    login_with(@moderator.user_name, @moderator.password)

    get reports_path(format: 'json')

    post_via_redirect report_repost_path(id: first_report.id, format: 'json')
    first_report.reload
    first_item.reload

    assert first_report.resolved
    assert_equal @moderator.id, first_report.resolver_user_id
    assert ::Report::Status::REPOSTED, first_report.status
    assert first_item.open?, 'Item should be re-listed open'

    assert_equal 0, Users::Notification.where(recipient_user_id: @first_parent.id, related_model_type: 'Report', related_model_id: first_report.id).not_deleted.count,
                 "Being reported parent should have ChildReported notification ended"


    # Check user blocks
    @second_child.reload
    assert_nil @second_child.boundaries.user_blocks.find{|ub| ub.content_type_id == @first_child.id }, "The seller should be OFF reporter's block list"

    puts "---- 2nd Report on Item #{second_item.id} - Deleting"
    logout
    login_with(@first_parent.user_name, @first_parent.password)

    delete_via_redirect report_path(id: second_report.id, format: 'json')
    second_report.reload
    second_item.reload

    assert second_report.resolved
    assert ::Report::Status::DELETED_BY_PARENT, second_report.status
    assert ::Item::Status::REPORT_DELETED, second_item.status

    puts "---- Moderator deleting"
    logout
    login_with(@moderator.user_name, @moderator.password)

    delete_via_redirect report_path(id: second_report.id, format: 'json')
    second_report.reload
    second_item.reload

    assert_equal @moderator.id, second_report.resolver_user_id
    assert second_report.resolved
    assert ::Report::Status::DELETED_BY_ADMIN, second_report.status
    assert ::Item::Status::REPORT_DELETED, second_item.status

    puts "==================="
  end

  protected

  # Setup users, items
  def setup
    @first_parent, @first_child = create_parent_and_child(:valid_father, :old_boy)
    login_with(@first_child.user_name, @first_child.password)

    # 1st item
    item_attr = attributes_for(:item_with_category_id)
    photo_attr = attributes_for(:photo_ff13)
    file_data = load_photo_file_data(photo_attr[:image])

    post '/items', item: item_attr.merge(
        :item_photos_attributes => [photo_attr.merge(image: file_data, default_photo: true)]
    )

    # 2nd item
    another_item_attr = attributes_for(:item_with_top_category)
    post '/items', item: another_item_attr.merge(
        :item_photos_attributes => [photo_attr.merge(image: file_data, default_photo: true)]
    )

    Item.all.each{|item| item.activate! }

    # Make child beyond new

    school = create(:daycare)
    @first_child.trade_count = 1
    @first_child.item_count = ::User::MINIMUM_ITEM_COUNT_BEYOND_NEW
    @first_child.current_school_id = school.id
    @first_child.save
    @first_child.update_school_group!(grade: ::Schools::SchoolGroup::PRE_KINDERGARDEN, teacher: 'Kenmore')
    @first_child.reload

    ####

    @second_parent, @second_child = create_parent_and_child(:valid_mother, :old_girl)
    @second_child.update_attributes(current_school_id: school.id)
    @second_child.update_school_group!(grade: ::Schools::SchoolGroup::PRE_KINDERGARDEN, teacher: 'Kenmore')

    @moderator = create(:moderator)

  end

end
