class CreateUserTracking < ActiveRecord::Migration
  def up
    create_table_unless_exists 'user_trackings' do|t|
      t.integer :user_id, null: false
      t.string  :ip, length: 127
      t.string  :system
      t.string  :browser
      t.string  :continent, length: 56
      t.string  :country, length: 127
      t.string  :city, length: 127
      t.string  :state, length: 56
      t.string  :zip, length: 56
      t.string  :timezone, length: 56
      t.datetime    :login_at
      t.datetime    :logout_at
    end
  end

  def down
    drop_table_if_exists 'user_trackings'
  end
end
