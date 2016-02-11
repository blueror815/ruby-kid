class AddIntendedAgeGroupToItems < ActiveRecord::Migration
  def change
    add_column_unless_exists :items, :intended_age_group, :string, length: 55, default: 'same'
  end
end
