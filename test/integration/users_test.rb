require 'test_helper'
require 'controller_helper'
require 'user_helper'
require 'item_helper'

class UsersTest < ActionDispatch::IntegrationTest

  include ControllerHelper
  include ItemHelper
  include UserHelper
  include ::Users::UserInfo

  test "Account confirmation" do
  #def do_test_account_confirmation
    parent, user = create_parent_and_child(:unconfirmed_parent, :unconfirmed_child)
    login_with(user.user_name, user.password)

    item_attr = attributes_for(:item_with_category_id)
    item_attr[:description] = "Final Item"
    photo_attr = attributes_for(:photo_ff13)
    file_data = load_photo_file_data(photo_attr[:image])
    post '/items', item: item_attr.merge(
        :item_photos_attributes => [photo_attr.merge(image: file_data, default_photo: true)]
    )

    assert parent.confirm_account!, "Should be able to confirm account with enough items"
  end


  # Help to login failure
  # test "Login Failure" do
  def go_test_login_failure
    login_with('nobody', 'dddasdfjdfk')
    assert response.body.match(/<input\s+.*value=["']Login["']/i), "Login should be a failure"
  end

  # Test submission to create new account
  test "Sign Up New User" do
  #def do_test_sign_up_new_user
    valid_user = build(:valid_parent)
    existing_user = User.last
    user_h = valid_user.attributes.select do |k, v|
      [:user_name, :email, :first_name, :last_name, :password].include?(k.to_sym)
    end
    user_h[:password] ||= 'somepassword'
    user_h[:password_confirmation] = 'xxxxxxxxxxxxx'
    post_via_redirect user_registration_path + '.json', user: user_h

    puts "================"
  end

  test 'Creating and Updating Main User' do
  #def do_create_and_updating_main_user
    user = create(:valid_parent)
    login_with(user.user_name, user.password)

    new_password = 'second1234'
    do_test_update_user(user, '/users', new_password)

    # Logout and Login with changed password
    delete destroy_user_session_path
    follow_redirect!


    login_with(user.user_name, new_password)

    puts "======================"
  end

  test 'Parent Creating and Updating a Child' do
  #def do_create_and_update_child

    user = create(:buying_parent)
    another_user, another_child = create_parent_and_child(:selling_parent, :selling_child)

    login_with(user.user_name, user.password)

    # Attempt to edit someone else's child
    put_via_redirect users_edit_child_path(id: another_child.id, format:'json')
    assert response.body.match(/#{I18n.translate('devise.registrations.no_permission')}/i), "Should not allow change to someone else's child"

    # Real creation of valid child
    valid_child_h = attributes_for(:buying_child).delete_if{|k,v| [:type, :encrypted_password].include?(k) }

    puts 'Creating 1st child ---------------------'
    post_via_redirect users_create_child_path, format:'json', user: valid_child_h, relationship_type: 'FATHER'
    created_child = User.find_by_user_name(valid_child_h[:user_name] )
    assert_not_nil created_child
    user.reload
    assert user.children.any? { |_child| _child.user_name == valid_child_h[:user_name] }, "Child #{valid_child_h[:user_name] } should be in the children list of parent #{user.user_name}"

    address = "999 Giant Steps Lane"
    address_h = {user_locations:[{ state:"NJ", city:"Hopewell", address:address, zip:"08525"}], user_phones:["1234569999"], user_location:[] }
    post_via_redirect user_locations_path(format:'json'), address_h

    response_json = JSON.parse(response.body)
    assert response_json['success']
    user.reload
    user_loc = user.user_locations.first
    assert_not_nil user_loc
    assert_equal address, user_loc.address

    # Attempt to create child with same first_name
    # school =
    school = create(:public_elementary)
    user_2_h = {user_name: created_child.user_name + '2', email: 'second' + created_child.email, first_name: created_child.first_name,
               last_name: created_child.last_name, password: valid_child_h[:password], password_confirmation: valid_child_h[:password],
               grade: Child::PARENT_GUIDANCE_GRADE_THRESHOLD, current_school_id: school.id, teacher: 'Johnson' }
    get users_new_child_path
    puts 'Creating 2nd child w/ same First Name ---------------------'
    post_via_redirect users_create_child_path, format:'json', user: user_2_h
    assert response.body.match(/#{I18n.t('child.registration.duplicate_first_name')}/i), "Should not be allowed to create another child with duplicate first name"

    puts 'Creating 2nd child, valid ---------------------'
    user_2_h[:first_name] = created_child.first_name + 'jr'
    user_2_h.delete(:email)
    post_via_redirect users_create_child_path, format:'json', user: user_2_h
    child_2 = Child.last
    assert_not_equal created_child.id, child_2.id, 'New 2nd child should be created, not same'

    # Update
    puts 'Updating 1st child --------------'
    profile_image_name = 'avatar-sea-turtle-small@2x'
    put users_update_child_path(id: created_child.id, user: {last_name: 'Johnson', interests: 'Mountain climbing', profile_image_name: profile_image_name} )
    follow_redirect!
    created_child.reload
    assert_equal 'Johnson', created_child.last_name
    assert_equal 'Mountain climbing', created_child.interests
    assert_equal profile_image_name, created_child.profile_image_name

    # Check for background job
    first_job = ::Delayed::Job.last
    handler = YAML::load(first_job.handler)
    assert handler.is_a?(::Jobs::ChildNeverPostedCheck)
    assert_equal created_child.id, handler.user_id
    handler.perform

    # Attempt to change to a taken user_name
    put users_update_child_path(created_child), user: {user_name: another_child.user_name}
    created_child.reload
    assert_not_equal created_child.user_name, another_child.user_name

    # Creation of address and phone number
    address_h = attributes_for(:valid_address)
    phone_h = attributes_for(:valid_number)
    post_via_redirect user_locations_path(format:'json', user_location: address_h, phone_number: phone_h[:number] )
    user.reload

    user_loc = user.user_locations.last
    assert_not_nil user_loc
    assert_equal address_h[:address], user_loc.address
    assert_equal address_h[:city], user_loc.city

    user_phone = user.user_phones.last
    assert_not_nil user_phone
    assert_equal phone_h[:number].gsub(/[\s\-]/, ''), user_phone.number.gsub(/[\s\-]/, '')

    # Change of address and phone number

    address_h2 = attributes_for(:boston_02184)
    phone_h2 = attributes_for(:boston_mobile)
    post_via_redirect user_locations_path(format:'json', user_locations: [address_h2], user_phones: [phone_h2] )
    user.reload

    assert_equal 1, user.user_locations.count, "The Array-based or multiple user_locations parameter should enforce replacement of all existing user_locations"
    user_loc = user.user_locations.last
    assert_equal address_h2[:address], user_loc.address
    assert_equal address_h2[:city], user_loc.city

    assert_equal 1, user.user_phones.count, "The Array-based or multiple user_phones parameter should enforce replacement of all existing user_phones"
    user_phone = user.user_phones.last
    assert_equal phone_h2[:number].gsub(/[\s\-]/, ''), user_phone.number.gsub(/[\s\-]/, '')

    ::Timecop.freeze(Time.now + ::Jobs::ChildNeverPostedCheck::TIME_LENGTH + 56.hours) do
      last_job = ::Delayed::Job.last
      last_handler = YAML::load(last_job.handler)
      assert last_handler.is_a?(::Jobs::ChildNeverPostedCheck)
      assert_not_equal first_job.id, last_job.id
      assert_equal created_child.id, last_handler.user_id
    end

    puts "======================"
  end

  test 'Child Registers and Updates Self - Younger' do
    child = create_child_registration(:elementary_child, :public_elementary, 4, 'Johnson')
    password = child.password || attributes_for(:elementary_child)[:password] # keep password for later use

    assert child.requires_parental_guidance?, "Child w/ grade #{child.grade} should require parental guidance"
    assert child.is_parent_email, 'Young child should be using parent email'

    puts 'Child updates self --------------'
    do_test_update_user(child)

    puts 'Check interaction eligibility'
    assert_equal false, check_eligibility(child)[:result], 'Young child should not be eligible for interactions'

    post_via_redirect api2_create_friend_request_path(format:'json', requested:30, message:'Wanna be friends')
    friend_h = JSON.parse(response.body)
    assert_equal false, friend_h['success']
    post create_friend_request_path(requested:30, message:'Wanna be friends')
    assert_equal 302, response.status

    puts 'Check Child trading eligibility'
    get api_show_eligibility_path(format:'json')
    elig_h = JSON.parse(response.body)
    assert_equal false, elig_h['can_trade']

    puts 'Sign up parent -----------------'
    parent_h = attributes_for(:valid_parent).select do |k, v|
      [:user_name, :first_name, :last_name, :gender, :password].include?(k.to_sym)
    end
    logout
    post_via_redirect user_registration_path, user: parent_h, child_id: child.id
    # post_via_redirect user_registration_path, user: parent_h
    assert request.path =~ /user_locations/, 'Page after parent registration should be user_locations'

    puts 'Recheck child eligibility --------------'
    child.reload
    assert_not_nil child.parent
    assert_equal parent_h[:user_name], child.parent.user_name
    assert child.finished_registering
    assert child.parent.finished_registering

    assert check_eligibility(child)[:result], 'Young child should be upgraded eligible for interactions'

    puts 'Check parent account info --------------'
    get api_show_current_user_path(format:'json')
    me_h = JSON.parse(response.body)
    assert_not_nil me_h['user']
    assert_equal parent_h[:user_name], me_h['user']['user_name']
    assert me_h['user']['email'].present?, 'Parent should have email by now.'

    puts 'Submit an address & phone -----------------'
    addr_h = attributes_for(:valid_address).select{|k,v| [:address, :address2, :city, :state, :zip].include?(k) }
    post_via_redirect user_locations_path(initial_reg: true, child_id: child.id, phone_number:'4159834903', users_user_location: addr_h)
    assert request.path =~ /users\/child\/#{child.id}\/school/, 'Page after submitting address should be school picker'

    puts 'Submit pick of school ------------------'
    create(:public_elementary)
    school = ::Schools::School.last
    put_via_redirect child_update_school_path(initial_reg: true, child_id: child.id, school_id: school.id )
    child.reload
    assert_equal school.id, child.current_school_id

    puts "=============="
  end

  test 'Child Registers and Updates Self - Older' do
  #def do_test_registered_child_older
    child = create_child_registration(:elementary_child, :public_elementary, 5, 'Yemens')

    assert !child.requires_parental_guidance?, "Child w/ grade #{child.grade} should not require parental guidance"
    assert !child.is_parent_email, 'Old child should not be using parent email'

    child.reload
    assert child.parent.nil?, 'Old child does not need parent'

    puts 'Child updates self --------------------'
    do_test_update_user(child)

    assert check_eligibility(child)[:result], 'Old child should be eligible for interactions'

    puts "=============="
  end

  test "Following Friends" do
  #def do_test_following_friends
    @buying_parent, @buyer = create_parent_and_child(:buying_parent, :buying_child)
    @selling_parent, @seller = create_parent_and_child(:selling_parent, :selling_child)

    login_with(@buyer.user_name, @buyer.password)

    post_via_redirect follow_user_path(id: @seller.id)

    @buyer.reload
    @seller.reload
    assert @buyer.followings.any?{|fol| fol.user_id == @seller.id }, "Buyer should get following of seller"
    assert @buyer.followed_users.any?{|fol| fol.id == @seller.id }, "Buyer should get seller in followed_users"

    assert @seller.followers.any?{|u| u.id == @buyer.id }, "Seller should get buyer in followers"

    logout
    login_with(@seller.user_name, @seller.password)

    puts "|- Now seller #{@seller.user_name} follows buyer #{@buyer.user_name}"
    post_via_redirect follow_user_path(id: @buyer.id)

    @buyer.reload
    @seller.reload

    #
    assert @seller.followings.any?{|fol| fol.user_id == @buyer.id }, "Seller should get following of buyer"
    assert @seller.followed_users.any?{|fol| fol.id == @buyer.id }, "Seller should get buyer in followed_users"

    assert @buyer.followers.any?{|u| u.id == @seller.id }, "Buyer should get seller in followers"
    assert @buyer.is_mutual_friend?(@seller.id), "Buyer's is_mutual_friend"
    assert @seller.is_mutual_friend?(@buyer.id), "Seller's is_mutual_friend"

    get_via_redirect users_friends_path(format: 'json')
    friends_hash = JSON.parse(response.body)
    users = friends_hash['users'] || []
    assert users.any?{|user_h| user_h['id'] == @buyer.id && user_h['is_mutual_friend'] == true }, "Friends JSON should have is_mutual_friend"

    #
    logout
    login_with(@buying_parent.user_name, @buying_parent.password)
    get_via_redirect api_specific_user_friends_path(user_id: @buyer.id, format: 'json')
    child_friends_h = JSON.parse(response.body)
    assert child_friends_h.present?
    assert child_friends_h['users'].present?
    assert child_friends_h['users'].find{|h| h['id'] == @seller.id }, "Should include seller in the response of friends for specific user"

    # Illegible access to other's child
    get_via_redirect api_specific_user_friends_path(user_id: @seller.id, format: 'json')
    access_h = JSON.parse(response.body)
    assert !access_h['success'], "Illegible access should not have passed through"
    assert access_h['users'].blank?, "Illegible access should not get any users in response"

    puts "  seller follows #{@seller.followings.count} merchants."
  end


  protected

  def setup
    User.all.each{|u| u.destroy } # users & user_relationships
  end


  # Common tests against the shoulds and should nots of users update

  def do_test_update_user(user, update_url = '/users', new_password = nil)
    # Change user_name
    original_user_name = user.user_name
    put update_url, user: {user_name: original_user_name + '2', last_name: 'Johnson', interests: 'Mountain climbing'}
    user.reload
    assert_equal original_user_name + '2', user.user_name
    assert_equal 'Johnson', user.last_name
    assert_equal 'Mountain climbing', user.interests

    # Change password w/o confirmation, so update should not pass
    new_password ||= 'second1234'
    put update_url, user: {password: new_password, last_name: 'Smith'}
    user.reload
    assert_not_equal user.last_name, 'Smith'

    # Change of password and another attribute
    put update_url, user: {password: new_password, password_confirmation: new_password, last_name: 'Robert'}
    user.reload
    assert_equal user.last_name, 'Robert'

    if user.is_a?(Parent)
      puts "---------- Parent updating user location"
      assert_equal 0, user.user_locations.count
      assert_equal 0, user.user_phones.count

      location = attributes_for(:valid_address)
      phone = attributes_for(:valid_number)

      # New
      put update_url, user_location: location, user_phone: phone
      user.reload
      assert_equal 1, user.user_locations.count
      primary_location = user.primary_user_location
      assert_not_nil primary_location
      assert_equal location[:address], primary_location.address
      assert_equal location[:city], primary_location.city

      primary_phone = user.user_phones.where(is_primary: true).first
      assert_not_nil primary_phone
      assert_equal phone[:number], primary_phone.number

      # Replace / update
      location2 = attributes_for(:sf_94118)
      phone2 = attributes_for(:sf_mobile)
      phone2.delete(:is_primary)
      put update_url, user_location: location2, user_phone: phone2
      user.reload
      assert_equal 1, user.user_locations.count
      primary_location = user.primary_user_location
      assert_not_nil primary_location
      assert_equal location2[:address], primary_location.address
      assert_equal location2[:city], primary_location.city

      primary_phone = user.user_phones.where(is_primary: true).first
      assert_not_nil primary_phone
      assert_equal phone2[:number], primary_phone.number

      # Test authentication
      # Somehow ensure to redo account_confirmed
      unless ::User::AUTO_CONFIRM_ACCOUNT
        user.account_confirmed = false
        user.save

        third_location_h = attributes_for(:boston_02184)
        post account_confirmation_payment_path(amount: 1.0, payment_method_nonce: 'fake-valid-no-indicators-nonce',
             user_location: third_location_h )
        user.reload
        last_user_location = user.user_locations.order('id').last
        assert user.primary_user_location.reviewed, "Primary user location should have reviewed=true"
        assert !last_user_location.reviewed, "New address different from primary should not have reviewed=true"
        assert user.account_confirmed
      end
    end
  end
end
