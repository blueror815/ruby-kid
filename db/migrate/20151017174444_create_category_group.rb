class CreateCategoryGroup < ActiveRecord::Migration
  def up
    create_table_unless_exists :category_groups do|t|
      t.string  :name, null: false, length: 127, default: ''
      t.string  :gender, default: '', length:16
      t.integer :lowest_age, default: 0
      t.integer :highest_age, default: 100
      t.string  :country, length: 255
    end

    add_index_unless_exists :category_groups, :gender
    add_index_unless_exists :category_groups, [:lowest_age, :highest_age]
    add_index_unless_exists :category_groups, :country

    create_table_unless_exists :categories_category_groups do|t|
      t.integer :category_group_id, null: false
      t.integer :category_id, null: false
    end
    add_index_unless_exists :categories_category_groups, :category_group_id
    add_index_unless_exists :categories_category_groups, :category_id

    if table_exists?(:category_groups)
      CategoryGroup.create( name:'Younger Boys', gender: 'MALE', lowest_age: 0, highest_age: 5 )
      CategoryGroup.create( name:'Younger Girls', gender: 'FEMALE', lowest_age: 0, highest_age: 5 )
      CategoryGroup.create( name:'Older Boys', gender: 'MALE', lowest_age: 6, highest_age: 18 )
      CategoryGroup.create( name:'Older Girls', gender: 'FEMALE', lowest_age: 6, highest_age: 18 )
    end
  end

  def down
    drop_table_if_exists :category_groups
  end
end
