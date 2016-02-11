class CreateFundRaisers < ActiveRecord::Migration
  def up
    create_table_unless_exists :fund_raisers do|t|
      t.string :name, null: false
      t.string :email
      t.string :school_name
      t.string :city_state
      t.timestamps
    end
  end

  def down
    drop_table_if_exists :fund_raisers
  end
end
