require 'test_helper'

class CategoryTest < ActiveSupport::TestCase

  test "Add Category and CategoryGroup" do
    cat = create(:robots_category)
    geeks_group = CategoryGroup.create(name:'Geeks', gender:'MALE', lowest_age:8, highest_age:23)
    cat.assign_to_category_group!(geeks_group)

    geeks_group.reload
    assert geeks_group.categories.include?(cat)

    mappings = geeks_group.category_group_mappings.to_a
    assert mappings.collect(&:category_id).include?(cat.id)

    # Second cat
    second_cat = create(:video_game_system_category)
    second_cat.assign_to_category_group!(geeks_group)

    assert geeks_group.categories.include?(second_cat)
    second_cat.reload

    mappings = geeks_group.category_group_mappings.order('order_index asc').to_a
    assert mappings.collect(&:category_id).include?(cat.id)
    assert_equal second_cat.id, mappings.last.category_id
    assert mappings.last.order_index > mappings.first.order_index

    # Same category to different group
    smart_boys = CategoryGroup.create(name:'Smart Girls', gender:'FEMALE', lowest_age:6, highest_age:18)
    cat.assign_to_category_group!(smart_boys)
    smart_boys.reload
    assert smart_boys.categories.include?(cat)
  end

  test "Category Group for User" do
    puts "Right CategoryGroup is given according to user's attributes =============="
    ::CategoryGroup.delete_all
    toddler = ::CategoryGroup.create(name: 'Baby to Toddler', lowest_age:1, highest_age:5)
    kiddy_boy = ::CategoryGroup.create(name: 'Kiddy Boy', lowest_age:6, highest_age:10, gender:'MALE')
    kiddy_girl = ::CategoryGroup.create(name: 'Kiddy Girl', lowest_age:6, highest_age:10, gender:'FEMALE')
    grown_girl = ::CategoryGroup.create(name: 'Grown Girl', lowest_age:11, gender:'FEMALE')
    teenage_boy = ::CategoryGroup.create(name: 'Teenage Boy', highest_age:14, gender:'MALE')

    g = ::CategoryGroup.for_user(Child.new(gender:'FEMALE', grade: ::Schools::SchoolGroup::PRE_KINDERGARDEN))
    assert_equal toddler.id, g.id

    g = ::CategoryGroup.for_user(Child.new(gender:'MALE', grade: ::Schools::SchoolGroup::PRE_KINDERGARDEN))
    assert_equal toddler.id, g.id

    g = ::CategoryGroup.for_user(Child.new(gender:'MALE', grade: 1))
    assert_equal kiddy_boy.id, g.id

    g = ::CategoryGroup.for_user(Child.new(gender:'FEMALE', grade: 1))
    assert_equal kiddy_girl.id, g.id

    g = ::CategoryGroup.for_user(Child.new(grade: 1))
    assert_nil g

    g = ::CategoryGroup.for_user(Child.new(gender:'FEMALE', grade: 7))
    assert_equal grown_girl.id, g.id

    g = ::CategoryGroup.for_user(Child.new(gender:'MALE', grade: 10)) # age 15
    assert_nil g

    g = ::CategoryGroup.for_user(Child.new(gender:'MALE', grade: 7)) # age 12
    assert_equal teenage_boy.id, g.id
  end
end