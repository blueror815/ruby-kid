class AddSellerIdToOfferBundleItems < ActiveRecord::Migration
  def change
    
    add_column_unless_exists :offer_bundles_items, :seller_id, :integer, :null => false
  end
end
