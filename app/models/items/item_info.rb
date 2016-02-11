##
# Accessors for querying special info of the item.

module Items
  module ItemInfo

    REQUIRES_ACCOUNT_CONFIRMATION_TO_ACTIVATE = ::Users::UserInfo::REQUIRES_ACCOUNT_CONFIRMATION_FOR_INTERACTIONS
    REQUIRES_PARENT_APPROVAL = false

    # Brief title of the item.  Title attribute is preferred over the body in limited characters.
    def display_title
      self.title.present? ? self.title : self.description.squeeze[0,40]
    end

    ##
    # Compares item owner with another_user.  It's more accurate to specify +action+ so specific rules like approval right
    # can be evaluated.
    # @param action <Symbol> :activate or :deactivate; the exact ones for manageable_by_user?.
    # @return <integer> combo of Users::Permission::FLAGS; 0 means GUEST/public

    def permission_to_user(another_user, action = :activate)
      return 0 if another_user.nil?
      if owned_by_user?(another_user)
        if manageable_by_user?(another_user, action)
          return ::Users::Permission::EditItem | ::Users::Permission::ManageItem
        else
          return ::Users::Permission::EditItem
        end
      else
        0
      end
    end

    def owned_by_user?(editor)
      return false if editor.nil?
      return true if editor.id == user_id
      if editor.is_a?(Parent)
        editor.children.collect(&:id).include?(user_id)
      else
        editor.parents.collect(&:id).include?(user_id)
      end
    end

    # Modifies and updates the item's information, but not activation.
    def editable_by_user?(editor)
      return false if editor.nil?
      return false if suspended? && !editor.is_a?(Admin)

      #if editor.is_a?(Child) && !pending?
      #  self.errors.add(:status, "After activation an item is only editable by the parent")
      #  false
      #else
      editor && (user_id == editor.id || manageable_by_user?(editor))
      #end
    end

    # Checks with the rights to activate, deactivate
    # @param editor <User>
    # @param action <Symbol> :activate or :deactivate
    def manageable_by_user?(editor, action = :activate)
      return false if suspended? && !editor.is_a?(Admin)

      if editor.is_a?(Parent)
        (new_record? || user_id == editor.id || editor.parent_of?(self.user))
      else
        editor && (user_id == editor.id) && (action.nil? || action == :deactivate || active? )
      end
    end

    def tradeable_to_user?(current_user)
      open? && current_user && !current_user.is_a?(Parent) && !owned_by_user?(current_user)
    end

    def open?
      status == ::Item::Status::OPEN
    end

    def pending_account_confirmation?
      status == ::Item::Status::PENDING_ACCOUNT_CONFIRMATION
    end

    def open_for_search?
      open?
    end

    def trading?
      status == ::Item::Status::TRADING
    end

    def buying?
      status == ::Item::Status::BUYING
    end

    def active?
      open? || trading? || buying?
    end

    # Stage yet activated
    def pending?
       [::Item::Status::PENDING, ::Item::Status::DRAFT].include?(status)
    end

    # Stage: activated before but not deactivated
    def ended?
      status == ::Item::Status::ENDED
    end

    def suspended?
      status == ::Item::Status::REPORT_SUSPENDED
    end

    def item_keywords_joined
      item_keywords.collect(&:keyword).join(',')
    end

    # category IDs (int) in order of level
    def category_ids
      categories.order(&:level).collect(&:id)
    end

    # root category ID
    def category_id
      @category_id ||= category_ids.first
    end

    def category
      @category ||= Category.find_by_id(category_id) || self.categories.order(&:level).first
    end

    def is_follower?(other_user)
      actual_user_id = (other_user.is_a?(User) ? other_user.id : other_user)
      return false if actual_user_id == user_id
      user.followers.where(id: actual_user_id).count > 0
    end

    ##
    # args: <Integer or Hash>
    #   If it is integer, it represents the viewer's or another user's ID
    #   :include_active_trade <boolean or nil> If specified, queries including active_trade.
    def as_json(options = {}, requesting_user_id = nil )
      #following the spec from teh apidocs
      #{activated_at: self.activated_at, age_group: self.age_group, default_thumbnail_url: self.default_thumbnail_url, description: self.description,
      # gender_group: self.gender_group, intended_age_group: self.intended_age_group, price: self.price, status: self.status, title: self.title,
      # user_id: self.owner.id, owner: self.owner.as_more_json({}, requesting_user_id), category: self.category, item_photos: self.item_photos}.stringify_keys
      item_h = super(options.merge(only: [:id, :title, :description, :item_keywords_string, :price, :user_id, :activated_at,
                                          :default_thumbnail_url, :activated_at, :status, :user_name, :age_group, :intended_age_group,
                                          :gender_group, :gender, :teacher, :profile_image_url, :category],
                                           methods: [:owner, :category]))
      item_h[:item_photos] = item_photos.limit(::ItemPhoto::MAX_ITEM_PHOTOS).collect(&:as_json)
      item_h[:owner] = self.owner.as_more_json({}, requesting_user_id) if requesting_user_id
      if options[:include_active_trade] && (trade_item = ::Trading::TradeItem.where(item_id: self.id).first ) # && trading?
        trade = trade_item.trade
        item_h[:active_trade] = trade.active_trade_info_for(self.user, self)
      else
        item_h[:active_trade] = self.active_trade_json
      end
      if self.active_buy_request
        item_h[:buy_request] = self.active_buy_request.active_trade_info
      end
      if not requesting_user_id.nil?
        user = User.find(requesting_user_id)
        item_count = Item.owned_by(user).count
      else
        item_count = 0
      end
      item_h[:trading_information] = {
            coefficients: {
            alpha: ::TradeConstants::ALPHA_COEFF,
            alpha_prime: ::TradeConstants::ALPHA_PRIME_COEFF,
            alpha_approval_required: ::TradeConstants::ALPHA_APPROVAL_REQUIRED,
            beta: ::TradeConstants::BETA_COEFF,
            beta_prime: ::TradeConstants::BETA_PRIME_COEFF,
            beta_approval_required: ::TradeConstants::BETA_APPROVAL_REQUIRED,
        },
          items_in_customers_shop: item_count,
          items_minimum_threshold: ::TradeConstants::ITEMS_MIN_THRESHOLD,
          items_low_warning_threshold: ::TradeConstants::ITEMS_LOW_WARNING_THRESHOLD
      }
      #item_h[:description] = self.description.unpack('U*').collect{|c| c > 10000 ? c.to_s(16).prepend("\\U000") : [c].pack("U")  }.join # special characters like emoticon need UTF-32 escaped code for IOS
      item_h.stringify_keys
    end

    ##
    # Additional options in calling as_json
    def more_json(options = {}, viewing_user_id)
      as_json( options.merge(include_active_trade: true), viewing_user_id )
    end


    ##
    # Intended for single item reference for detailed display, which means user and school information are separated into
    # own keys.  This includes item_photos also.
    # +options+
    #   :is_follower_user_id <integer> whether the specified user is a follower of the item seller
    #   :is_in_favorite_items <integer> whether the specified user has item in favorite items
    #   :is_in_cart <integer>
    # @return <Hash with keys 'item', 'user', 'school', 'is_follower', 'is_in_cart'>
    def detailed_json(options = {}, viewing_user_id)

      is_follower = false
      if options[:is_follower_user_id].present?
        is_follower = is_follower?(options[:is_follower_user_id])
      end
      h = {:user => user.as_more_json({}, viewing_user_id), :item => more_json({}, viewing_user_id), :is_follower => is_follower}
      h[:is_in_cart] = options[:is_in_cart] if options[:is_in_cart].present?

      if options[:is_in_favorite_items].present?
        h[:is_in_favorite_items] = ::Items::FavoriteItem.where(item_id: id, user_id: options[:is_in_favorite_items]).count > 0
      end
      h
    end

    def active_trade_attribute(attr)
      return nil if self.active_trade_json.blank?
      self.active_trade_json[attr]
    end

    def trading_sort_priority(extra_attributes = {}, auth_user_id)
      score = 0
      if self.active_trade_json
        if self.active_trade_json[:needs_action]
          score = 1000
        elsif self.active_trade_json[:trade][:completion_confirmed]
          score = 2
        elsif self.active_trade_json[:trade][:buyer_packed] and self.active_trade_json[:trade][:seller_packed]
          score = 100
        elsif not self.active_trade_json[:trade][:waiting_for_user_id].eql? auth_user_id
          score = 50
        end
      else
        score = 50
      end
      score
    end

    ##
    # For item owner's list of items shown in dashboard.
    # extra_attributes
    #   :favorite_counts <Hash of id => integer>.
    def owner_sort_priority(extra_attributes = {}, auth_user_id)
      score = (trading? ? 100 : (buying? ? 85 : (pending? ? 50 : 0) ) )
      if self.active_trade_json
        if self.active_trade_json[:needs_action]
          score += 200
        elsif not self.active_trade_json[:trade][:waiting_for_user_id].eql? auth_user_id
          score += 100
        end
      end
      if (favorite_counts = extra_attributes[:favorite_counts] ).is_a?(Hash)
        score += (favorite_counts.keys.include?(self.id) ? 30 : 0 )
      end
      score
    end

  end

end
