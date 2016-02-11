class AddTradeItemTitle < ActiveRecord::Migration
  def up
    
    add_column_unless_exists :notification_texts, :title_for_item, :string
    add_column_unless_exists :notification_texts, :subtitle_for_item, :string

    add_column_unless_exists :notification_texts, :title_for_trade, :string
    add_column_unless_exists :notification_texts, :subtitle_for_trade, :string
  end

  def down
  end
end
