class AddStatAttributesToItems < ActiveRecord::Migration
  def change
    add_column_unless_exists :items, :view_count, :integer, :default => 0
    add_column_unless_exists :items, :age_group, :string, :length => 24
    add_column_unless_exists :items, :gender_group, :string, :length => 55
    
  end
end
