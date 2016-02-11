##
# Attributes
#   sellers_items_map <Hash of seller_user_id => <Array of CartItem's> >
module Carts
  class Cart
    attr_accessor :current_user, :cookies, :sellers_items_map
    attr_reader :item_count

    SELLERS_ITEMS_MAP_COOKIE_KEY = 'cart_items'

    def initialize(current_user_or_cookies)
      self.sellers_items_map = {}
      if current_user_or_cookies.is_a?(User)
        self.current_user = current_user_or_cookies

      elsif current_user_or_cookies.is_a?(Hash) || current_user_or_cookies.is_a?(ActionDispatch::Cookies::CookieJar) || current_user_or_cookies.is_a?(Rack::Test::CookieJar)
        self.cookies = current_user_or_cookies
      end
      reload
    end

    # @return nil for not logged in, else total item_count 
    def load_cart_from_db
      return nil if current_user.nil?
      self.sellers_items_map = CartItem.where(user_id: current_user.id).includes(:item).group_by(&:seller_id)
      @item_count = CartItem.where(user_id: current_user.id).count
    end

    # @return nil for not logged in, else total item_count 
    def load_cart_from_cookie
      return nil if self.cookies.nil?
      cookie = self.cookies[SELLERS_ITEMS_MAP_COOKIE_KEY]
      begin
        self.sellers_items_map = cookie.blank? ? {} : ActiveSupport::JSON.decode(cookie)
        self.sellers_items_map.keys.each do |k|
          self.sellers_items_map[k.to_i] = self.sellers_items_map.delete(k).collect { |h| CartItem.new(h) } if k.is_a?(String) && k =~ /^\d+$/
        end
      rescue Exception => e
      end
      calculate_item_count!
    end

    # Reload the sellers_items_map by figuring out either by DB or cookies
    def reload
      load_cart_from_db || load_cart_from_cookie
    end

    def calculate_item_count!
      @item_count = 0
      self.sellers_items_map.values.each do |items|
        @item_count += items.size
      end
    end

    ## 
    # Generic item-adding operation.  If cart is loaded with logged-in user, changed CartItem will be saved.
    #   options
    #     :quantity_change => :update or :add, default is :add.  Whether to add onto or override(update) existing 
    #       quantity if item's already in cart.  In other words, an update to cart's item quantity would use :quantity_change => :update.
    def add_item(item, quantity = 1, options = {}, &block)
      return false if item.nil? || !item.open?

      quantity ||= 1 # why needs this for default argument value already above? 
      cart_items = self[item.user_id] || []
      citem = nil
      if (citem = cart_items.find { |cart_item| cart_item.item_id == item.id })
        citem.quantity = [item.quantity, (options[:quantity_change] == :update ? quantity.to_i : (citem.quantity + quantity.to_i))].min
        citem.user_id = current_user.try(:id)
      else
        citem = CartItem.new(item_id: item.id, user_id: current_user.try(:id), seller_id: item.user_id, quantity: [quantity.to_i, item.quantity].min)
        cart_items << citem
      end

      self.sellers_items_map[item.user_id] = cart_items
      if current_user && citem.user_id
        citem.save
      elsif cookies
        save_sellers_items_to_cookies
      end

      calculate_item_count!

      yield sellers_items_map if block_given?

      true
    end

    # Can be either updating item quantity or deleting item, depending on the quantity given
    def update_item(item, quantity = 1, &block)
      if quantity == 0
        delete_item(item, &block)
      else
        add_item(item, quantity, quantity_change: :update, &block)
      end
    end

    def delete_item(item, &block)
      cart_items = self[item.user_id]
      return false if cart_items.blank?

      original_size = cart_items.size
      cart_items.delete_if do |citem|
        if citem.item_id == item.id
          CartItem.destroy(citem.id) if current_user && citem.id
          true
        else
          false
        end
      end
      status = cart_items.size < original_size
      if status
        self.sellers_items_map[item.user_id] = cart_items

        save_sellers_items_to_cookies if cookies

        calculate_item_count!
      end

      yield self.sellers_items_map if block_given?

      status
    end

    alias_method :remove_item, :delete_item

    # Clears away records of cart times of all or specific seller
    def clear(seller_id = nil)
      # Clear all sellers' items
      if seller_id.blank?
        self.sellers_items_map.clear
        @item_count = 0
        if current_user
          CartItem.delete_all ["user_id = ?", current_user.id]
        end
        save_sellers_items_to_cookies if cookies

      else
        if (deleted_seller_items = self.sellers_items_map.delete(seller_id))
          if current_user
            deleted_seller_items.each { |citem| CartItem.destroy(citem.id) if citem.id && citem.seller_id == seller_id }
          elsif cookies
            save_sellers_items_to_cookies
          end
        end
      end

    end

    ########################
    # Accessor Methods

    # seller_id <User or User#id>
    def [](seller_id)
      self.sellers_items_map[seller_id.is_a?(User) ? seller_id.id : seller_id]
    end

    def get_cart_item_of(item)
      seller_cart_items = self[item.user_id] || []
      seller_cart_items.find { |citem| citem.item_id == item.id }
    end

    # Fetches the User object of seller_id from a preloaded-cache of User objects instead of separate database calls.
    # @return <User> the seller of items
    def get_seller_object_of(seller_id)
      load_seller_objects_map[seller_id]
    end

    # yield: <User>, <Array of CartItem>
    def for_each_seller(&block)
      sellers_items_map.each_pair do |k, v|
        yield get_seller_object_of(k), v
      end
    end

    # @options:
    #   :seller_id or 'seller_id' - specifically filter items to only those of this seller
    # @return <Array of <Hash with keys 'item_id', 'quantity', 'seller_id'> >
    def as_json(options = nil)
      seller_id = options ? (options.delete('seller_id') || options.delete(:seller_id) ) : nil
      items_ar = []
      for_each_seller do|seller, citems|
        next if seller_id && seller.id != seller_id
        citems.each do|citem|
          items_ar << citem.attributes.select{|k,v| %w(item_id quantity seller_id).include?(k) }
        end
      end
      items_ar
    end

    protected

    def save_sellers_items_to_cookies
      self.cookies[SELLERS_ITEMS_MAP_COOKIE_KEY] = ActiveSupport::JSON.encode(sellers_items_map)
    end

    def load_seller_objects_map
      unless @seller_objects_map
        @seller_objects_map = {}
        User.find(sellers_items_map.keys).each do |u|
          @seller_objects_map[u.id] = u
        end
      end
      @seller_objects_map
    end

  end
end