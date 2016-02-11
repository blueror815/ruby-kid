require 'test_helper'
require 'controller_helper'
require 'user_helper'

class SchoolsTest < ActionDispatch::IntegrationTest

  include ControllerHelper
  include UserHelper


  test "Create and Search School" do

    NAME_REGEX = /hopewell\s+community\s+school/i

    post_via_redirect schools_path(format:'json', school:{ name:'Hopewell Community School', address:'101 Broad St', city:'Hopewell', state:'NJ', zip:'08525' })
    json_response = JSON.parse(response.body)
    assert json_response["name"].to_s =~ NAME_REGEX, "Created school hash in response should be same name"
    assert json_response['zip'].to_s =~ /08525/
    school_id = json_response['id']
    school = ::Schools::School.find_by_id(school_id)
    assert_not_nil school

    get schools_path(format:'json', query: 'hopewell community')
    schools_list_h = JSON.parse(response.body)
    assert_not_nil schools_list_h.find{|school_h| school_h['name'] =~ NAME_REGEX }, "Search by name should include created school"

    get schools_path(format:'json', zip: '08525')
    schools_list_h = JSON.parse(response.body)
    assert_not_nil schools_list_h.find{|school_h| school_h['name'] =~ NAME_REGEX }, "Search by zip should include created school"

    # Another school not-existing zip
    ANOTHER_NAME_REGEX = /auto power school/i

    post_via_redirect schools_path(format:'json', school:{ name:'Auto Power School', address:'100 Power ST', city:'Quincy', state:'CA', zip:'09899' })

    get schools_path(format:'json', zip: '09899')
    schools_list_h = JSON.parse(response.body)
    assert_not_nil schools_list_h.find{|school_h| school_h['name'] =~ ANOTHER_NAME_REGEX }, "Search by zip should include created school"

    get schools_path(format:'json', zip: '09899-3100')
    schools_list_h = JSON.parse(response.body)
    assert_not_nil schools_list_h.find{|school_h| school_h['name'] =~ ANOTHER_NAME_REGEX }, "Search by detailed-zip should include created school"

    puts "======================="

  end


  protected

  def setup
    User.all.each{|u| u.destroy } # users & user_relationships

    @buying_parent, @buyer = create_parent_and_child(:buying_parent, :buying_child)

    login_with(@buying_parent.user_name, @buying_parent.password)

  end
end