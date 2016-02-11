module Carts
  module CartsHelper
    
    def make_offer_params(cart_items)
      h = { item_id: cart_items.collect(&:item_id) }
      cart_items.each do|cart_item|
        h["quantity_of_#{cart_item.item_id}".to_sym] = cart_item.quantity
      end
      h
    end
    
  end
end
