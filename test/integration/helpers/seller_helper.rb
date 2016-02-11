module Integration
  module Helpers
    module SellerHelper


      ##
      # Build trades based on given Item factory keys for user
      def build_user_items(user, items_factory_keys)

        items = []
        1.upto(::User::MINIMUM_ITEM_COUNT_BEYOND_NEW) do |i|
          factory_k = items_factory_keys[ i % items_factory_keys.size ]
          _item = build(factory_k, :activated)
          _item.title << " No. #{i + 1}"
          _item.description << " of Item No. #{i + 1}"
          _item.user = user
          _item.save
          items << _item
        end
        items

        puts "    user #{user.user_name} has #{Item.where(user_id: user.id).count} items"
        puts "--------------------"
        
        items
      end

    end
  end
end
