require 'test_helper'
require 'user_helper'

class UserTest < ActiveSupport::TestCase

  include UserHelper

  test "Creating Children in Schools" do
  # def do_creating_children
    assert @buyer.is_a?(Child)
    assert_equal @buyer.current_school_id, @friend.current_school_id, "Should have same current school"
    assert @buyer.is_within_circle?(@friend), "Friend should be within circle"
    assert @friend.is_within_circle?(@buyer), "Buyer should be within friend's circle"

    puts "| search_users_in_circle of #{@buyer.user_name}"
    search = User.search_users_in_circle(@buyer)
    assert (search.total > 0), "Search should have users in results"
    assert search.results.collect(&:id).include?(@friend.id), "Search should have friend in results"

    puts "| search_users_in_circle of #{@friend.user_name}"
    search = User.search_users_in_circle(@friend)
    assert (search.total > 0), "Search should have users in results"
    assert search.results.collect(&:id).include?(@buyer.id), "Search should have buyer in results"

    puts "| create more children"

    # Same school, same grade, but different teacher
    @old_boy = create(:elementary_child_2)
    @old_boy.update_attributes(current_school_id: @buyer.current_school_id)
    @old_boy.update_school_group!(grade: @buyer.grade, teacher: 'Nobody')

    # Same school, same teacher, but out of range grade
    @old_girl = create(:elementary_child)
    @old_girl.update_attributes(current_school_id: @buyer.current_school_id)
    @old_girl.update_school_group!(grade: @buyer.grade + 5, teacher: @buyer.teacher)

    User.reindex

    search = User.search_users_in_circle(@friend)
    assert search.results.collect(&:id).include?(@old_boy.id)
    #assert !search.results.collect(&:id).include?(@old_girl.id)

    puts "================="
  end

  # Against User#family_users and User#family_user_ids
  test "Family Users" do
    parent = @buyer_parent.reload
    another_child = Child.new( attributes_for(:selling_child).select{|k,v| [:type, :encrypted_password].exclude?(k.to_sym)} )
    another_child.copy_parent_info(parent)
    another_child.save
    parent.add_child!( another_child )

    third_child = Child.new( attributes_for(:elementary_child_2).select{|k,v| [:type, :encrypted_password].exclude?(k.to_sym)} )
    third_child.copy_parent_info(parent)

    third_child.save
    parent.add_child!( third_child )
    parent.save
    parent.reload

    assert_equal 3, parent.children.count
    children_ids = parent.children.collect(&:id)

    assert_equal children_ids, parent.family_user_ids
    @buyer.reload
    assert_equal children_ids, @buyer.family_user_ids

  end

  protected

  def setup
    User.all.each{|u| u.destroy } # Clear away user_relationships too

    @buyer = create(:tiger_child)
    @buyer.reload
    @buyer_parent = @buyer.parent

    last_job = ::Delayed::Job.last
    handler = YAML::load(last_job.handler)
    assert handler.is_a?(::Jobs::ChildLoginReminder), "There should have a ChildLoginReminder for child #{@buyer.id}"
    assert_equal @buyer.id, handler.user_id, "Reminder should be for child #{@buyer.id}"
    assert_nil @buyer.last_sign_in_at
    Timecop.freeze(DateTime.now + ::Jobs::UserCheck::TIME_LENGTH + 1.hour) do
      handler.perform
      nm = ::NotificationMail.last
      assert_equal @buyer_parent.id, nm.recipient_user_id
    end

    @friend = create(:tiger_child_classmate)
    @friend.current_school_id = @buyer.current_school_id
    @friend.save
    @friend.update_school_group!(grade: @buyer.grade, teacher: @buyer.teacher)

    @friend.reload
    User.reindex
  end
end
