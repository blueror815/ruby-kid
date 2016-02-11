class AddAddress2ToUser < ActiveRecord::Migration
  def change
    add_column_unless_exists :user_locations, :address2, :string
  end
end
