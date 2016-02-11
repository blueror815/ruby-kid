class AddAgreementsToOfferBundles < ActiveRecord::Migration
  def change
    
    add_column_unless_exists :offer_bundles, :buyer_agree, :boolean, :default => false
    add_column_unless_exists :offer_bundles, :seller_agree, :boolean, :default => false
    
  end
end
