class AddBNoteTexts < ActiveRecord::Migration
  def up
    add_column_unless_exists :notification_texts, :title_for_trade_b, :string
    add_column_unless_exists :notification_texts, :tip_for_trade_b, :string
    add_column_unless_exists :notification_texts, :title_for_item_b, :string
    add_column_unless_exists :notification_texts, :tip_for_item_b, :string
  end

  def down
    remove_column :notification_texts, :title_for_trade_b
    remove_column :notification_texts, :tip_for_item_b
    remove_column :notification_texts, :title_for_item_b
    remove_column :notification_texts, :tip_for_trade_b
  end
end
