require 'test_helper'
require 'controller_helper'
require 'user_helper'
require 'item_helper'

class AccountConfirmationTest < ActionDispatch::IntegrationTest

  include ControllerHelper
  include UserHelper
  include ItemHelper

  test "Children can't access account confirmation" do
    parent, child = create_parent_and_child(:valid_father, :old_boy)
    parent.save!

    login_with(child.user_name, child.password)

    get account_confirmation_path
    assert_redirected_to notifications_path # until web fully implemented, no reach to dashboard yet: users_dashboard_path

    parent.delete
    child.delete
  end

  test "Unconfirmed parent with enough items can access confirmation page" do
    parent, child = create_parent_and_child(:valid_father, :old_boy)
    parent.account_confirmed = false
    parent.save!

    login_with(child.user_name, child.password)
    upload_enough_items_for_account_confirmation child
    logout

    login_with(parent.user_name, parent.password)

    unless ::User::AUTO_CONFIRM_ACCOUNT
      get account_confirmation_path
      assert_response :success
    end
    parent.delete
    child.delete
  end

  test "Parent shoul get an email when the user uploads enough items" do
    parent, child = create_parent_and_child(:valid_father, :old_boy)
    parent.account_confirmed = false
    parent.save!

    login_with(child.user_name, child.password)
    upload_enough_items_for_account_confirmation child

    email = NotificationMail.where(recipient_id: parent.id, related_type: :parent_account_confirmation)
    assert email, "Parent should have gotten an email"

    parent.delete
    child.delete
  end

  test "Confirmation is successful" do
    parent, child = create_parent_and_child(:valid_father, :old_boy)
    parent.account_confirmed = false
    parent.save!

    login_with(child.user_name, child.password)
    upload_enough_items_for_account_confirmation child
    logout

    login_with(parent.user_name, parent.password)

    unless ::User::AUTO_CONFIRM_ACCOUNT
      get account_confirmation_path
      assert_response :success

      post account_confirmation_payment_path(payment_method_nonce: "fake-valid-nonce")
      assert_template :account_confirmed
    end
    parent.reload
    assert parent.account_confirmed, "Should have been confirmed"

    parent.delete
    child.delete
  end

  test "Failed to charge card" do
    parent, child = create_parent_and_child(:valid_father, :old_boy)
    parent.account_confirmed = false
    parent.save!

    login_with(child.user_name, child.password)
    upload_enough_items_for_account_confirmation child
    logout

    login_with(parent.user_name, parent.password)

    unless ::User::AUTO_CONFIRM_ACCOUNT
      get account_confirmation_path
      assert_response :success

      # Test amounts via: https://developers.braintreepayments.com/ios+php/reference/general/testing#test-amounts
      post account_confirmation_payment_path(payment_method_nonce: "fake-valid-nonce", test_amount: "2061.00")
      assert_template :index
      assert flash[:error] == "Unable to charge card.", "Flash should signify failure"

      post account_confirmation_payment_path(payment_method_nonce: "fake-valid-nonce", test_amount: "2000.00")
      assert_template :index
      assert flash[:error] == "Unable to charge card.", "Flash should signify failure"

      parent.reload
      assert !parent.account_confirmed, "Should not have been confirmed"
    end
    parent.delete
    child.delete
  end


  test "Already confirmed parent goes to dashboard" do
    parent, child = create_parent_and_child(:valid_father, :old_boy)
    parent.account_confirmed = true
    parent.save!

    login_with(parent.user_name, parent.password)

    get account_confirmation_path
    assert_redirected_to notifications_path # until web fully implemented, no reach to dashboard yet: users_dashboard_path

    parent.delete
    child.delete
  end

  test "Successful payment page not accessible without payment nonce" do
    parent, child = create_parent_and_child(:valid_father, :old_boy)
    parent.account_confirmed = true
    parent.save!

    login_with(parent.user_name, parent.password)

    post account_confirmation_payment_path
    assert_redirected_to notifications_path # until web fully implemented, no reach to dashboard yet: users_dashboard_path

    parent.delete
    child.delete
  end
end