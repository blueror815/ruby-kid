module Trading
  class TradeItem < ActiveRecord::Base
    self.table_name = 'trades_items'
    
    attr_accessible :trade_id, :item_id, :seller_id, :quantity
    
    belongs_to :item
    belongs_to :seller, class_name: 'User', :foreign_key => 'seller_id'
    belongs_to :trade, class_name: 'Trading::Trade'

    before_create :set_associations
    after_create :update_trade!
    
    def update_trade!
      return if self.item.nil?
      if trade.is_buyer_side?(seller_id)
        trade.update_attributes(status: ::Trading::Trade::Status::OPEN, buyer_agree: false)
      else
        trade.update_attributes(status: ::Trading::Trade::Status::OPEN, seller_agree: false)
      end

      ::Items::FavoriteItem.delete_all(item_id: item_id, user_id: (seller_id == trade.seller_id ? trade.buyer_id : trade.seller_id)  )
    end

    def set_associations
      self.seller_id ||= self.item.user_id
    end

    def display_name
      self.item.title # or whatever column you want
    end

  end
end
