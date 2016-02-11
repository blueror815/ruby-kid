class AddGenderToUser < ActiveRecord::Migration
  def change
    add_column_unless_exists :users, :gender, :string
  end
end
