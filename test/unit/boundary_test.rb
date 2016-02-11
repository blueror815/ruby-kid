require 'test_helper'
require 'user_helper'
require 'item_helper'

class BoundaryTest < ActiveSupport::TestCase

  include UserHelper
  include ItemHelper

  test "Item Search with Boundaries" do
    assert @child.boundaries.present?
    search = ::Item.build_search({}, @child)
    sunspot_params = search.query.to_params

    # This comparison of SOLR DSL query syntax depends on its the system's syntax.
    fq = sunspot_params[:fq]
    puts '-' * 20
    puts fq
    puts '-' * 20
    assert fq.present?
    assert fq.find{|q| q =~ /\-category_ids.*:.*#{@category.id}/ }, "Search query should include exclusion of category #{@category.id}"
    assert fq.find{|q| q =~ /\-user_id.*:.*#{@user_block.content_value}/ }, "Search query should include exclusion of user #{@user_block.content_value}"
    #assert fq.find{|q| q =~ /^grade_/ }, "Search query should include grade boundary"

    assert sunspot_params[:q].present?
    #assert ( sunspot_params[:q] =~ /\-#{@keyword_block.content_value}/i ), "Search query should include exclusion of keyword #{@keyword_block.content_value}"

    puts "======================="
  end

  protected

  def setup
    User.delete_all

    @child = create(:tiger_child)
    @child.reload

    @category = create(:legos_category)
    @category_block = ::Users::CategoryBlock.new(user_id: @child.id, content_type_id: @category.id )

    @child_circle_option = ::Users::ChildCircleOption.new(user_id: @child.id, content_keyword: 'ONE_GRADE_AROUND')

    @keyword_block = ::Users::KeywordBlock.new(user_id: @child.id, content_keyword: 'gun')

    @user_block = ::Users::UserBlock.new(user_id: @child.id, content_type_id: 15)

    [@category_block, @keyword_block, @user_block, @child_circle_option].each do|b|
      puts '%5d | %30s | %s' % [b.user_id, b.type, b.content_value.to_s]
      @child.boundaries << b
    end

    @child.save
    @child.reload

  end

end
