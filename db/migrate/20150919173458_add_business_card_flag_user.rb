class AddBusinessCardFlagUser < ActiveRecord::Migration
  def up
    add_column_unless_exists :users, :business_card_note_sent, :boolean, default: false
  end

  def down
    remove_column :users, :business_card_note_sent
  end
end
