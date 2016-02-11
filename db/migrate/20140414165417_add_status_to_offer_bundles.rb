class AddStatusToOfferBundles < ActiveRecord::Migration
  def change
    add_column_unless_exists :offer_bundles, :status, :string, :default => 'OPEN'
    add_index_unless_exists :offer_bundles, :status
    add_index_unless_exists :offer_bundles, [:buyer_id, :seller_id]
  end
end
