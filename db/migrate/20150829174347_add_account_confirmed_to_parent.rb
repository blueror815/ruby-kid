class AddAccountConfirmedToParent < ActiveRecord::Migration
  def change
    add_column :users, :account_confirmed, :boolean, null: false, default: false
  end
end
