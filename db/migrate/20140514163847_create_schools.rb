class CreateSchools < ActiveRecord::Migration
  def change
    create_table_unless_exists :schools do |t|
      t.string :type, null: false
      t.string :name, null: false
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.string :country, default: 'United States'
      t.float :latitude
      t.float :longitude

    end
  end
end
