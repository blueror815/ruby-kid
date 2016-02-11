class CreateOfferResponses < ActiveRecord::Migration
  def change
    create_table :offer_responses do |t|
      t.integer :offer_bundle_id, :null => false
      t.integer :item_id
      t.integer :user_id, :null => false
      t.string :comment
      t.float :price
      t.integer :parent_id
      t.string :status

      t.timestamps
    end
    add_index_unless_exists :offer_responses, :offer_bundle_id
    add_index_unless_exists :offer_responses, :user_id
  end
end
