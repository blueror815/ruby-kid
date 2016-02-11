require 'test_helper'
require 'controller_helper'
require 'user_helper'
require 'item_helper'

class BoundariesTest < ActionDispatch::IntegrationTest

  include ControllerHelper
  include UserHelper
  include ItemHelper

  test "Set Boundaries" do

    category = create(:legos_category)
    child_circle_option = 'GRADE_ONLY'
    keyword_block = 'gun'
    request_params = { format: 'json', child_circle_option: child_circle_option,
        block_user_ids:"#{@second_child.id}, #{@second_parent.id}", block_keywords: keyword_block, block_category_ids:[category.id] }

    put_via_redirect boundaries_path(request_params)
    @first_child.reload
    @first_child.boundaries.reload

    assert @first_child.boundaries.child_circle_options.find{|b| b.content_value == child_circle_option }, "There should be a ChildCircleOption boundary set to #{child_circle_option}"
    assert @first_child.boundaries.category_blocks.find{|b| b.content_value == category.id }, "There should be a CategoryBlock boundary set to #{category.id}"
    assert @first_child.boundaries.user_blocks.find{|b| b.content_value == @second_child.id }, "There should be a UserBlock boundary set to #{@second_child.id}"
    assert @first_child.boundaries.user_blocks.find{|b| b.content_value == @second_parent.id }, "There should be a UserBlock boundary set to #{@second_parent.id}"
    assert @first_child.boundaries.keyword_blocks.find{|b| b.content_value == keyword_block }, "There should be a KeywordBlock boundary set to #{keyword_block}"

    logout
    login_with(@first_parent.user_name, @first_parent.password)
    puts "First parent tries to update child's boundaries"

    put_via_redirect boundaries_path(request_params.merge({id: @first_child.id } ) )
    assert_equal 200, response.status, "Parent's update request should be successful"

    #######

    logout
    login_with(@second_parent.user_name, @second_parent.password)
    puts "Second parent tries to update child's boundaries"

    put_via_redirect boundaries_path(request_params.merge({id: @first_child.id } ) )
    assert_not_equal 200, response.status, "Parent's update request should fail"


    puts "==================="
  end

  protected

  # Setup users, items
  def setup
    @first_parent, @first_child = create_parent_and_child(:valid_father, :old_boy)
    login_with(@first_child.user_name, @first_child.password)

    @second_parent, @second_child = create_parent_and_child(:valid_mother, :old_girl)
  end

end
