##
# 
module UserHelper

  ##
  # Instead of calling factory_girl's build or create, extracts needed attributes to create record in DB.
  # @return <user_class> instance
  def create_user_of(factory_key, user_class, extra_attributes = {})
    user_h = attributes_for(factory_key)
    user_h.delete(:type)
    user_h.delete(:encrypted_password)
    password = user_h[:password]
    user = User.find_by_user_name user_h[:user_name]
    user ||= user_class.new(user_h)
    user.password = password
    user.email = user.user_name + '-' + user.email
    if extra_attributes
      if (parent_id = extra_attributes.delete(:parent_id) )
        user.parent_id = parent_id 
      end
      user.attributes = extra_attributes
    end
    user.save
    user
  end

  def upload_enough_items_for_account_confirmation(user)
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

    Item.owned_by(user).each do |item|
      item.index!
    end
  end

  ## 
  # Using create_user_of to create users in DB based on factory attributes.
  # relationship <NSString> optional.  If specified, passes onto parent.add_child!(child, relationship) to specific relationship type
  # @return <Array of [parent, child] >
  def create_parent_and_child(parent_factory_key, child_factory_key, relationship = nil)
    parent = create_user_of(parent_factory_key, Parent)
    child = create_user_of(child_factory_key, Child, parent_id: parent.id )
    child.copy_parent_info(parent)
    child.save
    parent.add_child!(child, relationship)
    parent.save
    child.reload
    
    #puts "Parent #{parent.id} #{parent.user_name}, w/ children #{parent.children.collect(&:user_name)}"
    #puts "Child #{child.id} #{child.user_name} / parents #{child.parents.collect(&:user_name)}"

    [parent, child]
  end

  ##
  # Creates a child of certain school, grade, and teacher, including signed-in assertion.
  def create_child_registration(user_factory_key, school_factory_key, grade, teacher)
    user_h = attributes_for(user_factory_key)
    user_h.delete(:type)
    user_h.delete(:encrypted_password)
    User.where(user_name: user_h[:user_name] ).delete_all

    school = create(school_factory_key)
    user_h[:current_school_id] = school.id
    user_h[:grade] = grade
    user_h[:teacher] = teacher

    puts 'Child registers self -------------- '
    post users_create_student_path(format:'json', user: user_h )

    child = User.find_by_user_name(user_h[:user_name])
    child.password = user_h[:password]
    assert_not_nil child
    assert_equal school.id, child.current_school_id
    assert_equal teacher, child.teacher
    assert_equal grade, child.grade

    puts 'See if child is signed in'
    get api_show_current_user_path(format:'json')
    me_h = JSON.parse(response.body)
    assert_not_nil me_h['user']
    assert_equal child.user_name, me_h['user']['user_name']

    child
  end

  def build_trade_with_items( buyer_items_factory_keys, seller_items_factory_keys)
    @buying_parent, @buyer = create_parent_and_child(:buying_parent, :buying_child)
    @selling_parent, @seller = create_parent_and_child(:selling_parent, :selling_child)
    puts "Buyer: #{@buyer.user_name}"
    puts "Seller: #{@seller.user_name}"

    buyer_items = buyer_items_factory_keys.collect do |factory_k|
      _item = build(factory_k, :activated)
      _item.user = @buyer
      _item.save
      _item
    end
    seller_items = seller_items_factory_keys.collect do |factory_k|
      _item = build(factory_k, :activated)
      _item.user = @seller
      _item.save
      _item
    end

    login_with(@buyer.user_name, @buyer.password)

    # Buyer views item
    one_item = seller_items.last
    get item_path(one_item)
    # Invite to trade
    one_offer_attr = attributes_for(:trade_only_question)
    post create_trade_path(item_id: one_item.id, comment: one_offer_attr[:comment], format: 'json', skip_eligibility_check: true)

    @trade = ::Trading::Trade.where(seller_id: one_item.user_id, buyer_id: @buyer.id).active.last
  end
end