module Trading
  class BuyRequestItem < ::ActiveRecord::Base

    self.table_name = 'buy_requests_items'

    attr_accessible :buy_request_id, :item_id

    belongs_to :buy_request
    belongs_to :item

  end
end