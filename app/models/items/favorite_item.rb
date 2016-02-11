module Items
  class FavoriteItem < ActiveRecord::Base

    attr_accessible :user_id, :item_id, :published, :created_at

    default_scope where(:published => true)

    belongs_to :user
    belongs_to :item

    after_create :create_notification!

    # @return <boolean> whether item is now in favorites
    def self.toggle_item_to_favorites(item_id, user_id)
      fav = where(item_id: item_id, user_id: user_id, published: true).last
      if fav
        fav.published = false
        fav.created_at = DateTime.now
        fav.save
        false
      else
        old_fav = where(item_id: item_id, user_id: user_id, published: false).last
        if old_fav #it was unliked recently.
          if old_fav.created_at > (DateTime.now - 1.week)
            old_fav.published = true
            old_fav.save
            true
          else
            old_fav.destroy
            create(item_id: item_id, user_id: user_id)
            true
          end
        else
          create(item_id: item_id, user_id: user_id)
          true
        end
      end
    end

    def self.add_item_to_favorites(item_id, user_id)
      unless where(item_id: item_id, user_id: user_id).present?
        create(item_id: item_id, user_id: user_id)
      end
    end

    ##
    # Generate a hash of number of users liking/favoring the items.
    # @item_ids <either Integer or Array> used as a parameter to query favorite items.
    # @which_buyer_id <Integer> optional; limit only to this buyer's
    # @return <Hash of item_id => integer>
    def self.make_favorite_counts_map(item_ids, which_buyer_id = nil)
      items = self.where(item_id: item_ids)
      items = items.where(user_id: which_buyer_id) if which_buyer_id
      fav_lists_map = items.group_by(&:item_id) # item_id => <Array>
      fav_counts_map = {}
      fav_lists_map.each_pair do|k, v|
        fav_counts_map[k] = v.size
      end
      fav_counts_map
    end

    ##
    # Sort by priorities: in favorites, item ID desc
    # @which_buyer_id <Integer> optional; limit only to this buyer's
    # @return <Hash of item_id => integer count users who set favorite item> same returned from make_favorite_counts_map
    def self.sort_items_by_favorite_counts!(items, which_buyer_id = nil)
      favorite_map = ::Items::FavoriteItem.make_favorite_counts_map(items.collect(&:id), which_buyer_id)
      items.sort! do|item_a, item_b|
        if favorite_map[item_a.id] && favorite_map[item_b.id].nil?
          -1
        elsif favorite_map[item_a.id].nil? && favorite_map[item_b.id]
          1
        else
          item_b.id <=> item_a.id
        end
      end
      favorite_map
    end

    def create_notification!
      return nil if item.nil?
      notification = ::Users::Notifications::LikeItem.create(sender_user_id: user_id, recipient_user_id: item.user_id,
                                   uri: Rails.application.routes.url_helpers.item_path(item),
                                   related_model_type: item.class.to_s, related_model_id: item.id
      )
      #UserMailer.favorite_item(self.item, self.user).deliver
      notification
    end

    private

  end
end
