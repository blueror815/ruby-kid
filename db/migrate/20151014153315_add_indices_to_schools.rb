class AddIndicesToSchools < ActiveRecord::Migration
  def change
    add_column_unless_exists :schools, :created_at, :datetime, default: Time.local(0,0,0, 1,10,2015, nil,nil, true, -5)
    add_index_unless_exists :schools, :created_at
    add_index_unless_exists :schools, :validated_admin
  end
end
