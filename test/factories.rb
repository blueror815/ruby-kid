##
# factory_key: <String or symbol> would be the FactoryGirl's factory key used in build or create.
# primary_attribute: <String or symbol> the attribute, for example :user_name, that holds the primary key value 
#   to determine the existence of the record.
def find_or_create(factory_key, primary_attribute)
  record = build(factory_key)
  primary_value = record.try(primary_attribute)
  cur = record.class.where(primary_attribute.to_sym => primary_value).first
  if cur
    cur 
  else
    create(factory_key)
  end
end

FactoryGirl.define do

  factory :user do
    factory :unknown_type_user do
      user_name 'unknown_user'
      first_name 'Unknown'
      email 'uknown_user333@gmail.com'
      encrypted_password 'asdfkjasfj98er'
      password 'test1234'
    end
  end

  factory :parent do
    factory :valid_parent, aliases: [:selling_parent] do
      type 'Parent'
      user_name 'bgangster'
      first_name 'Brian'
      last_name 'Gan'
      email 'briangangster@me.com'
      gender 'MALE'
      encrypted_password 'kasdfjdsfkdjf'
      password 'test1234'
      account_confirmed true
    end

    factory :valid_father do
      type 'Parent'
      user_name 'bgman'
      first_name 'BG'
      email 'bgman@kidstrade.com'
      gender 'MALE'
      encrypted_password 'jka32f98234fs'
      password 'test1234'
      account_confirmed true
    end
    
    factory :valid_mother do
      type 'Parent'
      user_name 'fen'
      first_name 'Fen'
      email 'fennie718@hotmail.com'
      gender 'FEMALE'
      encrypted_password 'jkasdf98234fs'
      password 'test1234'
      account_confirmed true
    end

    factory :search_parent do
      type 'Parent'
      user_name 'searcher_parent'
      first_name 'First'
      last_name 'Last'
      email 'search_parent@me.com'
      gender 'MALE'
      encrypted_password 'kasdfjdsfkdjf'
      password 'test1234'
      account_confirmed true
    end

    factory :tiger_parent, aliases: [:buying_parent] do
      type 'Parent'
      user_name 'mommy_tiger'
      first_name 'Mommy'
      last_name 'Tiger'
      email 'mommy_tiger@mail.com'
      gender 'FEMALE'
      encrypted_password '25hd6abbgb4e4'
      password 'test1234'
      account_confirmed true
    end

    factory :chicken_parent do
      type 'Parent'
      user_name 'daddy_chicken'
      first_name 'Rooster'
      last_name 'Chicken'
      email 'daddy_chicken@mail.com'
      gender 'MALE'
      encrypted_password 'sdk324bgb4e4'
      password 'test1234'
      account_confirmed true
    end

    factory :unconfirmed_parent do
      type 'Parent'
      user_name 'unconfirmed_parent_username'
      first_name 'John'
      last_name 'Smith'
      email 'user@example.org'
      gender 'MALE'
      encrypted_password 'sdk324bgb4e4'
      password 'test1234'
      account_confirmed false
    end
  end

  factory :child do
    factory :valid_child, aliases: [:selling_child] do
      type 'Child'
      user_name 'kelly'
      first_name 'Kelly'
      last_name 'Gee'
      email 'briangan@email.com'
      gender 'FEMALE'
      encrypted_password 'sdfwefr234sadfdsa'
      password 'test1234'

      before(:create) do |child|
        p = create(:valid_parent)
        child.copy_parent_info(p)
        child.parents = [p]
      end
      after(:create) do|child|
        child.parents.each do|p|
          p.add_child!(child)
          p.save
        end
      end
    end

    factory :search_child do
      type 'Child'
      user_name 'searcher'
      first_name 'First'
      last_name 'Last'
      email 'searcher@email.com'
      gender 'FEMALE'
      encrypted_password 'sdfwefr234sadfdsa'
      password 'test1234'

      before(:create) do |child|
        p = create(:search_parent)
        child.copy_parent_info(p)
        child.parents = [p]
      end
      after(:create) do|child|
        child.parents.each do|p|
          p.add_child!(child)
          p.save
        end
      end
    end

    factory :tiger_child, aliases: [:buying_child] do
      type 'Child'
      user_name 'macy'
      first_name 'Macy'
      last_name 'Tiger'
      email 'macy@email.com'
      gender 'FEMALE'
      encrypted_password '8hkka8eh3jd'
      password 'test1234'

      after(:build) do |child|
        p = create(:tiger_parent)
        child.copy_parent_info(p)
        child.parents = [p]
      end

      after(:create) do |child|
        child.parents.each do|p|
          p.add_child!(child)
          p.save
        end
        school = find_or_create(:daycare, :id)
        child.schools = [school]
        child.current_school_id = school.id
        child.save
        child.update_school_group!(teacher: 'Aimie', grade: 100)
      end
    end

    # Classmate of tiger_child
    factory :chicken_child, aliases: [:chicken_girl, :tiger_child_classmate] do
      type 'Child'
      user_name 'chicky'
      first_name 'Chicky'
      last_name 'Chicken'
      email 'chicky@email.com'
      gender 'FEMALE'
      encrypted_password 'uwer832rnjasdjf'
      password 'test1234'

      before(:create) do|child|
        p = create(:chicken_parent)
        child.copy_parent_info(p)
        child.parents = [p]
      end
      after(:build) do |child|
        child.parents = [build(:chicken_parent)]
      end

      after(:create) do |child|
        child.parents.each do|p|
          p.add_child!(child, 'Mother')
          p.save
        end
        school = create(:daycare)
        child.schools = [school]
        child.current_school_id = school.id
        child.save
        child.update_school_group!(teacher: 'Aimie', grade: 100)
      end
    end

    factory :elementary_child, aliases: [:old_girl] do
      type 'Child'
      user_name 'kello'
      first_name 'Kello'
      last_name 'Coco'
      email 'kelloy@email.com'
      gender 'FEMALE'
      encrypted_password 'uwer832rnjasdjf'
      password 'test1234'

      after(:build) do |child|
        child.parents = [find_or_create(:valid_mother, :user_name)]
        child.parent_id = child.parents.first.id
      end

      after(:create) do |child|
        school = create(:public_elementary)
        child.schools = [school]
        child.current_school_id = school.id
        child.save
        child.update_school_group!(teacher: 'Yemens', grade: 2)
      end
    end

    factory :elementary_child_2, aliases: [:old_boy] do
      type 'Child'
      user_name 'kevin'
      first_name 'Kevin'
      last_name 'Coco'
      email 'kevin@email.com'
      gender 'MALE'
      encrypted_password 'uwer832rnjasdjf'
      password 'test1234'

      after(:build) do |child|
        child.parents = [find_or_create(:valid_father, :user_name)]
        child.parent_id = child.parents.first.id
      end

      after(:create) do |child|
        school = create(:public_elementary)
        child.schools = [school]
        child.current_school_id = school.id
        child.save
        child.update_school_group!(teacher: 'Yemens', grade: 2)
      end
    end

    factory :unconfirmed_child  do
      type 'Child'
      user_name 'unconfirmed_child_username'
      first_name 'Billy'
      last_name 'Smith'
      email 'kidsdonthaveemails@example.org'
      gender 'FEMALE'
      encrypted_password 'sdfwefr234sadfdsa'
      password 'test1234'

      before(:create) do |child|
        p = create(:unconfirmed_parent)
        child.copy_parent_info(p)
        child.parents = [p]
      end
      after(:create) do|child|
        child.parents.each do|p|
          p.add_child!(child)
          p.save
        end
      end
    end
  end

  factory :admin do
    factory :moderator do
      type 'Admin'
      user_name 'moderator'
      first_name 'Super'
      last_name 'Man'
      email 'super@kidstrade.com'
      gender 'MALE'
      encrypted_password '32jfdsdfr83pmznjasdjf'
      password 'test1234'
    end
  end

  ####################################
  factory :child_care do
    factory :daycare, class: ::Schools::ChildCare do
      id { rand(5900) + 1000000 }
      type '::Schools::ChildCare'
      name 'Toddler Tech PreSchool'
      address '90 Adam ST'
      city 'Quincy'
      state 'MA'
      zip '02171'
      country 'United States'
    end
  end

  factory :pubic_grade_school do
    factory :public_elementary, class: ::Schools::PublicGradeSchool do
      id { rand(3235) + 1000000 }
      type '::Schools::PublicGradeSchool'
      name 'Monclair Elementary'
      address '200 Squantumn ST'
      city 'Quincy'
      state 'MA'
      zip '02171'
      country 'United States'
    end
  end

  ####################################
  factory :users do
    factory :user_location, class: ::Users::UserLocation do
      factory :valid_address, aliases: [:boston] do

        address '100 Hancock ST'
        address2 'APT A'
        city 'Quincy'
        state 'MA'
        zip '02171'
        country 'United States'
        latitude 1.5
        longitude 1.5
      end

      factory :boston_02184 do
        address '348 Union ST'
        address2 'UNIT B'
        city 'Braintree'
        state 'MA'
        zip '02184'
        country 'United States'
      end

      factory :sf_94118 do
        address '500 7th Ave'
        city 'San Francisco'
        state 'CA'
        zip '94118'
        country 'United States'
        latitude 1.5
        longitude 1.5
      end
    end

    #======================================
    factory :user_phone, class: ::Users::UserPhone do
      factory :valid_number, aliases: [:boston_home] do
        number '617 479 2008'
        phone_type 'HOME'
        is_primary true
      end

      factory :boston_mobile do
        number '617 7855659'
        phone_type 'MOBILE'
        is_primary false
      end

      factory :sf_mobile do
        number '415 234 7834'
        phone_type 'MOBILE'
        is_primary false
      end

      factory :work_number do
        number '617 798 3483 ext 234'
        phone_type 'WORK'
        is_primary false
      end

    end

  end


  ####################################
  # Attributes: full_path_ids, :level, :level_order, :name, :icon_label, :parent_category_id, :male_index, :female_index,
  #   :male_icon, :male_camera_background, :male_icon_background_color, :male_hides_name,
  #   :female_icon, :female_camera_background, :female_icon_background_color, :female_hides_name,
  #   :male_age_group, :female_age_group

  factory :category do
    factory :top_category do
      name "Collectibles"
      level 1
      level_order 0
      parent_category_id nil
    end

    factory :lone_top_category do
      name "Miscellaneous"
      level 1
      level_order 0
      parent_category_id nil
    end

    factory :sub_category, aliases:[:robots_category] do
      name "Robots"
      level 2
      level_order 0
      parent_category_id { create(:top_category).id }
    end

    factory :legos_category do
      name "Legos"
      level 1
      level_order 0
      parent_category_id nil
    end

    factory :books_category do
      name "Books"
      level 1
      level_order 0
      parent_category_id nil
    end

    factory :video_games_category do
      name "Video Games"
      level 1
      level_order 0
      parent_category_id nil
    end

    factory :video_game_system_category do
      name "Video Game System"
      level 1
      level_order 1
      parent_category_id nil
    end
  end

  ####################################
  # Items

  factory :item_photo do
    factory :photo_ff13 do
      name 'Final Fantasy 13'
      image "#{Rails.root}/app/assets/images/test/ff13.jpg"
    end

    factory :photo_dark_room do
      name 'Praying in Dark Room'
      image "#{Rails.root}/app/assets/images/test/dark_room.jpg"
    end

    factory :photo_lake do
      name 'Lake Scenery'
      image "#{Rails.root}/app/assets/images/test/lake.jpg"
    end

    factory :photo_url_elephant do
      name 'Elephant'
      url "http://www.kidstrade.com/assets/avatars/elephant@2x.png"
      width 200
      height 200
    end

    factory :photo_url_leopard do
      name 'Leopard'
      url "http://www.kidstrade.com/assets/avatars/leopard@2x.png"
      width 200
      height 200
    end

    factory :photo_url_shoe do
      name 'Hello Kitty Shoe'
      url "https://s3.amazonaws.com/cubbyshop-uploads/test/test2/hello_kitty_shoe.jpg"
      width 200
      height 200
    end

    factory :photo_url_sports_car do
      name 'Sports Car'
      url "https://s3.amazonaws.com/cubbyshop-uploads/sports_car.jpg"
      width 200
      height 200
    end
  end

  factory :item do

    trait :activated do
      activated_at { rand(20).days.ago }
      status { Item::Status::OPEN }
    end

    trait :pending do
      activated_at nil
      status { Item::Status::PENDING }
    end

    trait :draft do
      activated_at nil
      status { Item::Status::DRAFT }
    end

    trait :with_user do
      association :user, factory: :valid_child
    end

    # This one's a partially complete item, with user set as :valid_child
    factory :item_by_child do
      association :user, factory: :valid_child
      title 'Item without category'
      price 1.5
      description 'MyText'
      intended_age_group 'same'
    end

    factory :item_without_category, parent: :item_by_child do
      association categories: []
    end

    factory :item_with_category_id, parent: :item_by_child do
      category_id { create(:sub_category).id }
      title 'The Valid Doll for Toddlers'
      price 1.79
      description 'With the needed info'
    end

    factory :item_with_top_category, parent: :item_by_child do
      category_id { create(:lone_top_category).id }
      title 'Duplo Train Set Legos'
      price 19.99
      description 'For age 2 to 4. There total of 4 train carts plus 3 different dolls.'
    end

    # These do not have seller/user set

    factory :lego_train_set do
      category_id { create(:legos_category).id }
      title 'Train Set Legos'
      price 4.7
      description 'Has front black train, middle trains blue and green, and an action figure'
    end

    factory :lego_farm_tools do
      category_id { create(:legos_category).id }
      title 'Farm Tools Legos'
      price 3.9
      description 'Legos have rake, shovel, and stick'
    end

    factory :wii_game_item do
      category_id { create(:video_games_category).id }
      title 'Used Wii Game: Super Mario World'
      price 5.99
      description 'Still playable condition, no scatch, no break'
    end

    factory :wii_game_item_2 do
      category_id { create(:video_games_category).id }
      title 'Used Wii Game: Kirby'
      price 45.0
      description 'Nearly new, no scatch, no break'
    end

    factory :wii_system_item do
      category_id { create(:video_game_system_category).id }
      title 'Used Wii System'
      price 59
      description 'Functional condition, control pads still work'
    end

    factory :story_book_item do
      category_id { create(:books_category).id }
      title 'Disney Original Story Book of 3'
      price 7.5
      quantity 3
      description 'The choices are Winnie the Pooh Story, Snow White, and Frozen'
    end

    factory :story_book_item_2 do
      category_id { create(:books_category).id }
      title 'Curious George Book'
      price 5.0
      quantity 1
      description 'The smart, curious monkey with his buddy, man in yellow hat'
    end

    factory :nintendo_3ds_system do
      category_id { create(:video_game_system_category).id }
      title 'Nintendo 3DS portable game console'
      price 39
      description 'Only little scratched but functional condition. Also check out my games for this too'
    end

    factory :nintendo_3ds_game_item do
      category_id { create(:video_games_category).id }
      title 'Kirby 2 for Nintendo 3DS'
      price 4.5
      description 'Not sure what price a used game would be.  If you pay full price for the 3DS, maybe give you for free'
    end


  end

  #############################
  factory :notification_text do
    factory :test_cache do
      identifier 'hey_there_buddy'
      title 'testing title'
      subtitle 'other stuffs tip'
    end

    factory :trading_trade_notification do
      identifier 'trading_trade_notification'
      title 'dummy title'
      subtitle 'dummy tip'
    end
  end


  #############################
  # Trades

  factory :trade, class: 'Trading::Trade' do
    factory :single_video_game_trade do
      after(:build) do |trade|
        trade.items << build(:wii_game_item, :activated)
      end
    end

    factory :multiple_video_game_trade do
      after(:build) do |trade|
        trade.items = [build(:wii_game_item, :activated), build(:wii_system_item, :activated)] #, build(:story_book_item, :activated)]
      end
    end
  end

  factory :trade_comment, class: 'Trading::TradeComment' do
    factory :trade_only_question do
      comment 'How new is this item?'
    end
    factory :trade_price_only do
      price 9.95
    end
    factory :trade_question_and_price do
      price 12.29
      comment 'Do you deliver to Seatle, WA?'
    end
  end
  #category keyword
  factory :category_keyword do
    factory :cat_keyword do
      category_id 10000
      keyword 'action figure'
    end
  end
end
