module Items
  class ItemSearch

    ###########################
    # Item Browse/Search

    ##
    # The maximum price of other items to collect into 1st set of items results.
    # @return <Float>
    def self.cutoff_of(original_price)
      price = original_price.round(2)
      if (0.01 .. 0.10).include?(price)
        price * 10.0
      elsif (0.11 .. 0.24).include?(price)
        price * 8.0
      elsif (0.25 .. 0.5).include?(price)
        price * 6.0
      elsif (0.51 .. 2.0).include?(price)
        price + 4.0
      elsif (2.01 .. 7.99).include?(price)
        price + 5.0
      elsif (8.0 .. 9.0).include?(price)
        price + 6.0
      else
        price * 1.5
      end
    end

    # @return <Array>, <Array>
    def self.sort_by_price_cutoff(items, price)
      within_list = [] # within the range of price up to cutoff
      outside_list = [] # under price or more than cutoff
      cutoff_price = cutoff_of(price)
      items.each do |item|
        if item.price <= cutoff_price
          within_list << item
        else
          outside_list << item
        end
      end
      within_list.sort! { |x, y| y.price <=> x.price } # descending
      outside_list.sort_by!(&:price)

      return within_list, outside_list
    end

  end
end