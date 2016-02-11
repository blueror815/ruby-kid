class AddIndexToOfferBundlesItems < ActiveRecord::Migration
  def change
    add_index_unless_exists :offer_bundles_items, :item_id
  end
end
