require 'test_helper'
require 'controller_helper'
require 'user_helper'
require 'item_helper'

class ItemsTest < ActionDispatch::IntegrationTest

  include ControllerHelper
  include UserHelper
  include ItemHelper

  SAMPLE_KEYWORDS = %w|hello kitty money doll barbie lego baseball playdoh cartoon pokemon anime musicbox|

  test 'Test create item for unconfirmed user' do
    parent, user = create_parent_and_child(:unconfirmed_parent, :unconfirmed_child)
    login_with(user.user_name, user.password)

    item_count = TradeConstants::NEW_USER_ITEMS_MIN_THRESHOLD.to_i
    item_count.times do |i|
        item_attr = attributes_for(:item_with_category_id)
        item_attr[:description] = "Item #{i + 1}"
        photo_attr = attributes_for(:photo_ff13)
        file_data = load_photo_file_data(photo_attr[:image])
        post '/items', item: item_attr.merge(
            :item_photos_attributes => [photo_attr.merge(image: file_data, default_photo: true)]
        )
    end

    items = Item.where(user_id: user.id)
    if ::Items::ItemInfo::REQUIRES_PARENT_APPROVAL
      items.each do |item|
        assert item.pending?, 'Status should be pending'
      end
    end

    items.each do |item|
      item.activate!
      if ::Items::ItemInfo::REQUIRES_ACCOUNT_CONFIRMATION_TO_ACTIVATE
        assert item.pending_account_confirmation?, 'Status should be pending account confirmation'
      else
        assert item.open?, 'Status should be OPEN'
        assert item.open_for_search?
      end
    end

    parent.confirm_account!

    items.each do |item|
      item.reload
      assert item.open?, 'Status should be open after account confirmation'
    end

    #last_note = ::Users::Notifications::ChildNewItem.sent_to(parent).last
    #assert_not_nil last_note, 'There should be a ChildNewItem notification to parent'

    last_nmail = ::NotificationMail.where('recipient_user_id = ? AND sender_user_id = ? AND related_type = ? AND created_at > ?',
      parent.id, user.id, ::Users::Notifications::ChildNewItem.get_type, 1.day.ago ).count
    assert_not_nil last_nmail
  end

  ##
  #def do_test_self_registered_child_postings
  test 'Self-Registered Child Item Posting - Younger' do
    item = make_self_registered_child_posting(:elementary_child, :public_elementary, 4, 'Johnson')
    assert item.pending?

    # Extra check against faulty update & falsely activate items
    item.owner.update_attributes(interests: 'Legos')
    item.reload
    assert item.pending?

    puts 'Sign up parent -----------------'
    parent_h = attributes_for(:valid_parent).select do |k, v|
      [:user_name, :email, :first_name, :last_name, :gender, :password].include?(k.to_sym)
    end
    post_via_redirect user_registration_path, user: parent_h

    get api_show_current_user_path(format:'json')
    me_h = JSON.parse(response.body)
    assert_not_nil me_h['user']
    assert_equal parent_h[:user_name], me_h['user']['user_name']

    item.reload
    assert item.open?

    puts '======================'
  end

  test 'Self-Registered Child Item Posting - Older' do
    item = make_self_registered_child_posting(:elementary_child, :public_elementary, 5, 'Johnson')
    assert item.open?
  end

  # @return <Item>
  def make_self_registered_child_posting(user_factory_key, school_factory_key, grade, teacher)
    user = create_child_registration(user_factory_key, school_factory_key, grade, teacher)

    item_attr = attributes_for(:item_with_category_id)

    photo_attr = attributes_for(:photo_ff13)
    file_data = load_photo_file_data(photo_attr[:image])

    puts "#{user.user_name} posting item -----------------"
    post '/items', item: item_attr.merge(
        :item_photos_attributes => [photo_attr.merge(image: file_data, default_photo: true)]
    )

    item = Item.where(user_id: user.id).last
    puts "Item: #{item}"
    assert_equal item_attr[:title], item.title
    assert item.intended_age_group.present?

    # Photos
    created_photo = item.item_photos.find { |p| p.name == photo_attr[:name] }
    assert_not_nil created_photo, "Should create a photo of #{photo_attr[:name]}"

    assert item.item_photos.all?{|p| p.image_url.present? }, "All created images should have URL"

    puts 'Update the title, keywords, and add another photo -----------'

    lake_photo_attr = attributes_for(:photo_lake)
    selected_keywords = SAMPLE_KEYWORDS[0..4]

    put "/items/#{item.id}", item: item_attr.merge(
        title: 'Changed Title', item_keywords_string: selected_keywords.join(','),
        item_photos_attributes: [lake_photo_attr.merge(image: load_photo_file_data(lake_photo_attr[:image]))]
    )
    item.reload
    assert_equal 'Changed Title', item.title
    updated_keywords = item.item_keywords.collect(&:keyword)
    selected_keywords.each do |kw|
      assert_not_nil updated_keywords.find { |skw| skw =~ /#{kw}/i }, "Item keywords should include the word #{kw} inside #{updated_keywords.inspect}"
    end
    assert_equal 2, item.item_photos.count, "Should have 2 photos added"
    lake_photo = item.item_photos.find { |p| p.name == lake_photo_attr[:name] }
    assert_not_nil lake_photo, "Should create a photo of #{lake_photo_attr[:name]}"

    item
  end

  def do_test_create_item_with_photo_urls
  #test "Create item with photo URLs" do
    puts "=================================\nCreate item with photo URLs"
    parent, user = create_parent_and_child(:buying_parent, :buying_child)
    login_with(user.user_name, user.password)

    item_attr = attributes_for(:item_with_category_id)

    init_urls = [ {url: 'http://localhost/assets/logos/splash-bg-kids@2x.png', width:1000, height:500 },
                  {url:'http://localhost/assets/images/ui-bg_gloss-wave_35_f6a828_500x100.png', width:500, height:100 } ]

    post '/items', item: item_attr.merge(
        :item_photos => init_urls
    )

    item = Item.where(user_id: user.id).last
    assert_equal item_attr[:title], item.title
    assert item.intended_age_group.present?
    assert_equal init_urls.size, item.item_photos.size

    # Update with the same photos
    put "/items/#{item.id}", item: item_attr.merge( title: "Update with same photos", item_photos: item.item_photos.collect{|iphoto| iphoto.remote_image_url || iphoto.image_url } )

    item.reload
    assert_equal init_urls.size, item.item_photos.size, "An update w/ the same photos URLs should not change existing photos"

    # Update the title, keywords, and add another photo
    second_photo_attr = attributes_for(:photo_url_sports_car)
    selected_keywords = SAMPLE_KEYWORDS[0..4]

    put "/items/#{item.id}", item: item_attr.merge(
        title: 'Changed Title', item_keywords_string: selected_keywords.join(','),
        item_photo_urls: [second_photo_attr] + item.item_photos.collect{|iphoto| iphoto.remote_image_url || iphoto.image_url }
    )
    item.reload

    assert_equal 'Changed Title', item.title
    updated_keywords = item.item_keywords.collect(&:keyword)
    selected_keywords.each do |kw|
      assert_not_nil updated_keywords.find { |skw| skw =~ /#{kw}/i }, "Item keywords should include the word #{kw} inside #{updated_keywords.inspect}"
    end

    assert_equal 1, item.item_photos.size, "This different set of photos would actually delete old photos"
    lake_photo = item.item_photos.find { |p| p.name == second_photo_attr[:name] }
    assert_not_nil lake_photo, "Should create a photo of #{second_photo_attr[:name]}"

    puts "------------------"
  end


  # Activate item with different users
  # Last pass: 2015-04-09

  test "Activate Items" do
  #def do_test_activate_items

    parent, child = create_parent_and_child(:valid_parent, :selling_child)
    child2 = create_user_of(:chicken_child, Child, parent_id: parent.id )
    child2.copy_parent_info(parent)
    child2.save
    parent.add_child!(child2)
    parent.save

    old_item_count = child.item_count # test user might be reused
    assert_nil child.last_sign_in_at

    Timecop.freeze(DateTime.now + ::Jobs::UserCheck::TIME_LENGTH + 56.hours) do
      login_with(child.user_name, child.password)

      # User status checks
      child.reload
      assert_not_nil child.last_sign_in_at
      last_job = ::Delayed::Job.last
      handler = YAML::load(last_job.handler)
      assert handler.is_a?(::Jobs::ChildPostingReminder)
      assert_equal child.id, handler.user_id, "The reminder should be for #{child.user_name}"

      handler.perform
      nm = ::NotificationMail.last
      assert_equal parent.id, nm.recipient_user_id
    end

    item_attr = attributes_for(:item_with_category_id)
    photo_attr = attributes_for(:photo_ff13)
    file_data = load_photo_file_data(photo_attr[:image])
    post '/items', item: item_attr.merge(
        :item_photos_attributes => [photo_attr.merge(image: file_data, default_photo: true)]
    )

    item = Item.where(user_id: child.id).last
    assert_equal item_attr[:title], item.title
    child.reload

    if ::Items::ItemInfo::REQUIRES_PARENT_APPROVAL
      assert item.pending?, 'Item should starts as pending'
      assert_equal old_item_count, child.item_count, "Item is not approved yet, so should not be counted in item_count"

      puts '----------------- Child trying to approve'

      put inventory_activate_item_path(id: item.id)
      assert_response :redirect
      item.reload
      assert item.pending?, "Item should be pending because child cannot approve item."

      parent.account_confirmed = false
      parent.save

      logout

      # Notification and email
      approval_notes = Users::Notifications::IsWaitingForApproval.where(recipient_user_id: parent.id)
      assert_equal 1, approval_notes.count
      job = Delayed::Job.last
      assert_not_nil job
      handler = YAML::load(job.handler)
      assert handler.is_a?(::Jobs::ItemApprovalReminder)
      assert_equal child.id, handler.user_id

      assert_equal :first, ::UserMailer.fetch_item_for_approval_status(item, parent), "Item Approval message to parent should be first"
      # Substitution of the background run
      nm = ::NotificationMail.make_from_mail(item.user_id, parent.id, UserMailer.item_for_approval(item, parent), 'item_for_approval' )
      nm.save

      Timecop.freeze(Time.now + 56.hours) do
        handler.perform
        reminder_nm = ::NotificationMail.last
        assert_equal handler.class.to_s, reminder_nm.related_type
        assert_equal child.id, reminder_nm.related_type_id
      end

      puts '------------------------ Parent approval'

      login_with(parent.user_name, parent.password)
      assert_equal inventory_approve_item_path, path, "Parent should be redirected to inventory_approve_item"

      put inventory_activate_item_path(item_ids: [item.id])

      item.reload
      if ::Item::REQUIRES_ACCOUNT_CONFIRMATION_TO_ACTIVATE
        assert_equal ::Item::Status::PENDING_ACCOUNT_CONFIRMATION, item.status, "Item should be PENDING_ACCOUNT_CONFIRMATION status"
      end
      unless ::User::AUTO_CONFIRM_ACCOUNT
        # Check account status
        account_confirm_note = ::Users::Notifications::NeedsAccountConfirm.where(recipient_user_id: parent.id).last
        assert_not_nil account_confirm_note
        confirm_job = ::Delayed::Job.last
        assert_not_nil confirm_job
        confirm_handler = YAML::load(confirm_job.handler)
        assert confirm_handler.is_a?(::Jobs::VerifyAccountReminder)
        assert_equal parent.id, confirm_handler.user_id
        Timecop.freeze(account_confirm_note.created_at + 25.hours) do
          confirm_handler.perform
          reminder_nm = ::NotificationMail.last
          assert_equal confirm_handler.class.to_s, reminder_nm.related_type
          assert_equal parent.id, reminder_nm.related_type_id
        end
      end

      logout
      login_with(parent.user_name, parent.password)

      puts '------------ Re-login with account_confirmed=false'
      if ::Item::REQUIRES_ACCOUNT_CONFIRMATION_TO_ACTIVATE
        assert_equal account_confirmation_path, path, "Parent w/ account_confirmed=false and pending items approval should be redirect to account_confirm"
      end
      parent.account_confirmed = true
      parent.save

    else
      assert item.open?, 'Since not requiring parent approval, child should create item initially already open'
      assert_equal (old_item_count + 1), child.item_count, 'Useer item_count should be incremented'
    end # item approval

    puts '------------- Second item'
    logout
    login_with(child.user_name, child.password)

    second_item_attr = attributes_for(:lego_train_set)
    post '/items', item: second_item_attr.merge(
                     :item_photos_attributes => [photo_attr.merge(image: file_data, default_photo: true)]
                 )
    second_item = Item.where(user_id: child.id).last
    assert_equal second_item_attr[:title], second_item.title

    if ::Items::ItemInfo::REQUIRES_PARENT_APPROVAL

      assert second_item.pending?, 'Item should starts as pending'

      puts '------------- Re-approve both items'
      logout
      login_with(parent.user_name, parent.password)

      put inventory_activate_item_path(item_ids: [item.id, second_item.id])

      item.reload
      second_item.reload
      assert item.open?, "Item should be activated now by parent."
      assert second_item.open?, "Second Item should be activated now by parent."

    else
      item.reload
      second_item.reload

    end # second_item approval

    child.reload
    assert_equal (old_item_count + 2), child.item_count, "Item is approved, so user.item_count should be updated"

    logout
    login_with(parent.user_name, parent.password)
    assert_equal notifications_path, path, 'After account verified, and no more items to approve, after-login page should be notifications'

    logout

    puts '---------------- Item Change by child again'

    Timecop.freeze(DateTime.now + 1.hour) do
      login_with(child.user_name, child.password)
      put item_path(id: item.id, item: {:description => "#{item.description} + by child #{Time.now}"})
      item.reload
      if ::Items::ItemInfo::REQUIRES_PARENT_APPROVAL
        assert item.pending?, "Item should be pending AGAIN after child updates it."

        child.reload
        assert_equal 1, child.item_count, "Item is back pending, so should not be counted in item_count"

        logout
        assert_equal :reapprove, ::UserMailer.fetch_item_for_approval_status(item, parent), "Item Approval message to parent should be reapproval"
      end
    end

    puts '--------------------- Second child posting'

    logout
    login_with(child2.user_name, child2.password)

    another_item_attr = attributes_for(:item_with_top_category)
    post '/items', item: another_item_attr.merge(
                     :item_photos_attributes => [photo_attr.merge(image: file_data, default_photo: true)]
                 )
    another_item = Item.where(user_id: child2.id).last
    assert another_item.valid?, "Another item should be valid.  Errors: #{another_item.errors.full_messages}"
    another_item.save

    if ::Items::ItemInfo::REQUIRES_PARENT_APPROVAL
      approval_notes = Users::Notifications::IsWaitingForApproval.where(recipient_user_id: parent.id)
      assert approval_notes.size >= 2
      assert approval_notes.collect(&:sender_user_id).include?(child.id)
      assert approval_notes.collect(&:sender_user_id).include?(child2.id)
    end

    puts "-------------------- Parent's item update would auto approve"

    logout
    login_with(parent.user_name, parent.password)

    assert_equal notifications_path, path, 'Multiple kids to item approve, after-login page should be notifications'

    put item_path(id: item.id, item: {:description => "#{item.description} + by parent #{Time.now}"})
    item.reload
    assert item.open?, "Item should be approved after parent's update on item."

    child.reload
    assert_equal 2, child.item_count, "Item is approved, so user.item_count should be updated"

    logout

    puts '-------------------- End item'

    login_with(child.user_name, child.password)

    put inventory_deactivate_item_path(id: item.id)
    assert_response :redirect
    item.reload
    assert_equal Item::Status::ENDED, item.status, "Item should be deactivated with ended status"

    child.reload
    assert_equal 1, child.item_count, "Item is ended, so should not be counted in item_count"

    logout

    puts '------------------ Parent approve again'

    login_with(parent.user_name, parent.password)

    put inventory_activate_item_path(item_ids: [item.id, another_item.id])
    item.reload
    another_item.reload
    [item, another_item].each do |_item|
      assert _item.open?, "Item #{_item.title} should be activated open"
    end

    child.reload
    assert_equal 2, child.item_count, "Both items approved, so should be included in item_count"

    puts "Store items from public view"
    viewer = create(:buying_child)
    logout
    login_with(viewer.user_name, viewer.password)

    put toggle_favorite_item_path(id: item.id)

    get users_items_path(id: item.user_id, format: 'json', include_favorite_counts: true)

    h = JSON.parse(response.body)
    assert h['items'].present?
    assert_equal 2, h['items'].size
    assert h['favorite_counts'].present?
    assert_equal 1, h['favorite_counts'].size

    # Self likes
    get_via_redirect api_specific_favorite_items_path(user_id: viewer.id, format: 'json')
    likes_h = JSON.parse(response.body)
    assert likes_h.present?
    assert likes_h['favorite_item_ids'].include?(item.id), "In response, favorite_item_ids should include the item"

    get_via_redirect api_specific_favorite_items_path(user_id: child.id, format: 'json')
    access_h = JSON.parse(response.body)
    assert !access_h['success'], "Illegible access should not have passed through"
    assert access_h['users'].blank?, "Illegible access should not get any users in response"

    puts "------------------"
  end


  protected


  def setup
    User.delete_all
  end

end
