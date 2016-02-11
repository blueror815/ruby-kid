class AddQuantityToOfferBundlesItems < ActiveRecord::Migration
  def change
    add_column_unless_exists :offer_bundles_items, :quantity, :integer, :default => 1
  end
end
