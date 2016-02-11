class DropOffers < ActiveRecord::Migration
  def up

    drop_table_if_exists :offer_responses
    drop_table_if_exists :offer_bundles
    drop_table_if_exists :offer_bundles_items
  end

  def down
  end
end
