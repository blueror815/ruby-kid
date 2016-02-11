module Carts
  class CartItem < ActiveRecord::Base
    self.table_name = 'cart_items'
    
    attr_accessible :item_id, :quantity, :seller_id, :user_id
    
    belongs_to :seller, class_name: 'User'
    belongs_to :item
    
    def as_json(options = nil)
      super((options || {}).merge(only: [:id, :item_id, :quantity, :seller_id, :user_id] ) )
    end
  end
end