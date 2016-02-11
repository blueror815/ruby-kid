require 'test_helper'
require 'controller_helper'
require 'user_helper'

class SessionsTest < ActionDispatch::IntegrationTest

  include ControllerHelper
  include UserHelper

  def test_login_via_json
    get new_user_session_path
    post_via_redirect user_session_path + '.json', user: {login: 'someguy', password: 'xxxsdoifj33'}
    assert !JSON.parse(response.body)['success'], "This failed login should return success=false response"
    
    user = create_user_of(:valid_parent, Parent)
    post_via_redirect user_session_path + '.json', user: {login: user.user_name, password: user.password}
    login_response_h = JSON.parse(response.body)
    assert login_response_h['success'], "This login should return success response"
    assert login_response_h['authenticity_token'].present?, "Response: #{response.body}"
    
    get show_current_user_path + '.json'
    current_user_h = JSON.parse(response.body)
    
    assert current_user_h['success']
    assert current_user_h['id'].present?
    assert current_user_h['user_name'].present?
    assert_equal user.user_name, current_user_h['user_name']
    
    puts "\n------------- Login"
  end

end
