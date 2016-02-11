class AddDevices < ActiveRecord::Migration
  def up
    
    create_table_unless_exists(:devices) do |t|
      t.string :type, length: 127, null: false, default: 'Devices::Ios'
      t.integer :user_id, null: false
      t.string :push_token, length: 191
      t.timestamps
    end
    
    add_index_unless_exists :devices, :user_id
  end

  def down
  end
end
