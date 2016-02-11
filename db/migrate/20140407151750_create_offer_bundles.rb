class CreateOfferBundles < ActiveRecord::Migration
  def change
    create_table :offer_bundles do |t|
      t.integer :buyer_id, :null => false
      t.integer :seller_id, :null => false

      t.timestamps
    end
    add_index_unless_exists :offer_bundles, :buyer_id
    add_index_unless_exists :offer_bundles, :seller_id
    
    create_table :offer_bundles_items do|t|
      t.integer :offer_bundle_id, :null => false
      t.integer :item_id, :null => false
    end
    add_index_unless_exists :offer_bundles_items, :offer_bundle_id
  end
end
