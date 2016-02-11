class Trading::Trade < ActiveRecord::Base

  include ::Trading::TradesHandler
  include ::TradeConstants
  include ::Users::UserInfo

  attr_accessible :buyer_id, :seller_id, :buyer_agree, :seller_agree, :status, :waiting_for_user_id,
                  :last_meeting_place_set_by, :completed_at, :buyer_parent_approve, :seller_parent_approve, :sent_completed_notification,
                  :completion_confirmed, :buyer_packed, :seller_packed, :buyer_real_name, :seller_real_name, :denied, :reason_ended, :ended_by_user_id,
                  :other_reason


  object_constants :status, :open, :pending, :removed, :accepted, :ended, :completed

  has_many :trade_items, class_name: 'Trading::TradeItem', :dependent => :destroy
  has_and_belongs_to_many :items, :join_table => 'trades_items'
  has_many :trade_comments, class_name: 'Trading::TradeComment'

  belongs_to :buyer, :foreign_key => :buyer_id, class_name: 'User'
  belongs_to :seller, :foreign_key => :seller_id, class_name: 'User'

  serialize :denied, Array



  #special booleans just for if both the seller and buyer have expensive items.
  #both need to be set to true through the set_approve method in order for the trade to go through. Otherwise it gets set to false.
  # Custom accessors

  ACTIVE_STATUSES = ['OPEN', 'PENDING']
  STATUSES.each do |s|
    define_method "#{s.downcase}?" do
      status.to_s.upcase == "#{s}"
    end
  end
  alias_method :cancelled?, :ended?

  ##################
  # Scopes

  scope :active, conditions: ["status IN (?)", ACTIVE_STATUSES]
  scope :accepted, conditions: ["status = ?", Status::ACCEPTED]
  scope :completed, conditions: ["status = ?", Status::COMPLETED]
  scope :not_deleted, conditions: ["status NOT IN (?)", [Status::REMOVED, Status::ENDED] ]
  scope :for_user, lambda { |user_id| {conditions: ["buyer_id = ? OR seller_id = ?", user_id, user_id]} }
  scope :between_users, lambda { |first_user_id, second_user_id|
    {conditions: ["buyer_id IN (?) AND seller_id IN (?)", [first_user_id, second_user_id], [first_user_id, second_user_id]]}
  }

  before_save :set_defaults!

  REASON_ENDED = {not_ended: 0, not_given: 1, uneven: 2, changed_mind: 3, not_allowed: 4, dont_have: 5, cant_find: 6, other: 7}

  #[“UNEVEN”, “CHANGED_MIND”, “NOT_ALLOWED”, “DONT_HAVE”, “OTHER”]
  #NOT_GIVEN

  ##
  # Works for existing trade also as this will keep list of trade items unique.
  # Currently handled flow is A -> B -> A (accept or decline) -> meeting -> finished
  # @customer <User>
  # @items <Array of Item>

  def add_denied(item_id_array)
    self.denied = self.denied + item_id_array
    self.save
  end

  def reason_ended
    REASON_ENDED.key(read_attribute(:reason_ended))
  end

  def reason_ended=(reason)
    if not REASON_ENDED[reason].nil?
      write_attribute(:reason_ended, REASON_ENDED[reason])
    else
      write_attribute(:reason_ended, REASON_ENDED[:not_given])
    end
  end

  def add_items_to_trade!(customer, items, quantity_map = {} )
    return false if items.blank?
    item_owner_id = nil
    if new_record?
      items.each do |item|
        #self.items << item
        item_owner_id = item.user_id
        self.trade_items << ::Trading::TradeItem.new(trade_id: self.id, item_id: item.id, seller_id: item.user_id, quantity: quantity_map[item.id] )
      end

    else
      item_ids = self.items.collect(&:id)
      items.each do |item|
        if !item_ids.include?(item.id)
          item_owner_id = item.user_id
          #self.items << item
          self.trade_items << ::Trading::TradeItem.new(trade_id: self.id, item_id: item.id, seller_id: item.user_id, quantity: quantity_map[item.id] )
        end
      end

      self.waiting_for_user_id = self.the_other_user(customer).id
    end
    # this should check counter-counter-offer
    h = { status: (waiting_for_counter_offer? ? Status::OPEN : Status::PENDING) }
    if item_owner_id == buyer_id
      h[:buyer_agree] = h[:buyer_parent_approve] = false
      h[:seller_agree] = true # counter-offer

    elsif item_owner_id == seller_id
      h[:seller_agree] = h[:seller_parent_approve] = false
    end
    self.attributes = h
    self.save

    if self.status.eql? ::Trading::Trade::Status::PENDING
      create_offer_notification!(customer, {}, true)
    else
      create_offer_notification!(customer, {}, false)
    end
  end

  def self.create_message_for_completed_trades
    trades = ::Trading::Trade.where(status: ::Trading::Trade::Status::COMPLETED, sent_completed_notification: false)
    trades.each do |trade|
      four_days_ago = DateTime.now - 4.day
      #if four days ago is AFTER the trade completed date, send the notification.
      if trade.completed_at<= four_days_ago
        #::Users::Notifications::TradeCompletedCheck.create(trade, trade.buyer_id)
        #the below line will create it with the yellow bear as the sender. This won't work in the
        #cron_trade_notification branch, but will work with the changes that brian created.
        ::Users::Notifications::TradeCompletedCheck.create(trade, Admin.cubbyshop_admin, {recipient_user_id: trade.buyer_id})
        trade.waiting_for_user_id = trade.buyer_id
        trade.sent_completed_notification = true
        trade.save
      end
    end
  end

  def both_exp_approved?
    self.seller_parent_approve && self.buyer_parent_approve
  end


  # After search or creation of associated Trade, adds and saves this item onto the list if necessary.
  # +buyer+ <User>
  # +items+ <Item> or <Array of Item>
  # @return <Trading::Trade>
  def self.add_items_to_trade!(buyer, items)
    items = [items] if items.is_a?(Item)
    trade = get_trade_by_buyer_and_item(buyer, items)
    trade.add_items_to_trade!(buyer, items) if trade
    trade
  end

  # Finds the latest active trade between the buyer and item seller
  # The policy used to be a trial to find the existing buyer-associated active Trade that includes this item.
  # If none yet, initiates (not saved) new Trade.
  # +buyer+ <user_id or User>
  # +items+ <Item> or <Array of Item>

  def self.get_trade_by_buyer_and_item(buyer, item)
    return nil if item.nil?
    buyer_id = buyer.is_a?(User) ? buyer.id : buyer
    item = item.is_a?(Array) ? item.first : item
    trades = between_users(buyer_id, item.user_id).active.order('id desc')
    the_trade = trades.last

    # Not in any bundle, add onto another one
    if the_trade.nil?
      the_trade = trades.first
      the_trade ||= new(buyer_id: buyer.id, seller_id: item.user_id)
    end
    the_trade
  end


  def active?
    ACTIVE_STATUSES.include?(status.upcase)
  end

  def editable_by_user?(user)
    return false if user.nil?
    user.id == buyer_id || user.id == seller_id || buyer.parents.any? { |parent| parent.id == user.id } || seller.parents.any? { |parent| parent.id == user.id }
  end

  def user_agree?(user)
    is_buyer_side?(user) ? buyer_agree : seller_agree
  end

  ##
  # Sets the correct buyer_agree or seller_agree attribute depending on the user.
  def set_user_agree(user, agree_or_not = true)
    if is_buyer_side?(user)
      self.buyer_agree = agree_or_not
    else
      self.seller_agree = agree_or_not
    end
  end

  ##
  # Whether the user is either buyer child or the parent of the buyer.
  def is_buyer_side?(current_user)
    _user_id = current_user.is_a?(User) ? current_user.id : current_user
    if current_user.is_a?(Parent)
      buyer.parents.collect(&:id).include?(current_user.id)
    else
      _user_id == buyer_id
    end
  end

  ##
  # Whether the user is either seller child or the parent of the seller.
  def is_seller_side?(current_user)
    _user_id = current_user.is_a?(User) ? current_user.id : current_user
    if current_user.is_a?(Parent)
      seller.parents.collect(&:id).include?(current_user.id)
    else
      _user_id == seller_id
    end
  end

  def is_swap?
    items_of(buyer_id).present? && items_of(seller_id).present?
  end

  def breathing?
    self.completed? && !self.completion_confirmed
  end

  # +which_user_id+ <ID of User> optional. If defined, sets user_id condition in query for offers and given a price
  def latest_offer(which_user_id = nil)
    result = self.trade_comments.order('id desc')
    result = result.where(user_id: which_user_id) if which_user_id
    result.find { |o| o.price }
  end

  # The opposite user of this one
  # @return <User>
  def the_other_user(current_user)
    is_buyer_side?(current_user) ? self.seller : self.buyer
  end

  # +user+ <User or user's ID>
  # @return <Array of Items> items of this seller
  def items_of(current_user)
    user_id = current_user.is_a?(User) ? current_user.id : current_user
    users_items_map = self.trade_items.includes([:item]).collect(&:item).group_by(&:user_id)

    users_items_map[user_id] || []
  end

  ##
  # Opposite of items_of
  def wanted_items_of(buyer)
    items_of(the_other_user(buyer))
  end

  alias_method :items_of_the_other_user, :wanted_items_of

  # Fetches the wanted quantity of the item
  def quantity_of(item_id)
    if @item_quantity_map.blank?
      @item_quantity_map = {}
      self.trade_items.each do |ob_item|
        @item_quantity_map[ob_item.item_id] = ob_item.quantity
      end
    end
    @item_quantity_map[item_id] || 0
  end

  # Trade-related notifications.  Little too much for associations or scopes.
  def notifications
    ::Users::Notification.where(related_model_type: self.class.to_s, related_model_id: self.id)
  end

  def test_completion
    if self.buyer_packed and self.seller_packed
      self.sent_completed_notification = true
      self.save
      ::Users::Notifications::TradeCompletedCheck.create(self, Admin.cubbyshop_admin, {recipient_user_id: self.buyer_id})
    end
  end

  ##
  # Trade's own limited attributes, plus customer, merchant, and comments
  # +options+
  #   :customer <User> If set, helps to determine who else is the merchant.  Else the default customer is the buyer.
#   Trade Object
# ----
# {
#   ...
#   "information": {
#     "coefficients": {
#       "alpha": 0,
#       "alpha_prime": 0,
#           "alpha_approval_required": 0,
#           "beta": 0,
#           "beta_prime": 0,
#           "beta_approval_required": 0
#     },
#     "items_in_customers_shop" : 0,
#     "items_minimum_threshold": 0,
#     "items_low_warning_threshold": 0
#   }
# }
  def waiting_for_parent_approval_json?
    if items_of_seller_need_approval? and items_of_buyer_need_approval?
      !(buyer_parent_approve && seller_parent_approve)
    else
      #old parent approval check
      #needs_parent_approval? && !completed? && (!buyer_parent_approve && !seller_parent_approve)
      #if it needs parent approval, is not completed, and the buyer parent doesn't approve AND the seller parent doesn't Approve
      if not waiting_for_counter_offer?
        beta = who_is_beta
        if beta.eql?(-1) or items_of_seller_need_approval?
          !seller_parent_approve
        elsif (beta.eql?(1) || items_of_buyer_need_approval?) && buyer_agree && seller_agree
          !buyer_parent_approve
        else
          false
        end
      else
        false
      end
    end
  end

  def as_json(options = {}, auth_user_id = nil)
    cust_items = items.find_all{|_item| _item.user_id == buyer_id }
    merch_items = items.find_all{|_item| _item.user_id == seller_id }
    h = { id: id, status: status, waiting_for_user_id:  waiting_for_user_id, last_meeting_place_set_by: last_meeting_place_set_by }
    customer = options[:customer] || buyer
    h[:customer] = {
      user: buyer.as_more_json({}, seller_id, seller_real_name),
      items: cust_items.as_json()
    }

    h[:denied_item_ids] = denied
    h[:merchant] = {
      user: seller.as_more_json({}, buyer_id, buyer_real_name),
      items: merch_items.as_json()
    }
    if ended_by_user_id.present?
      if ended_by_user_id.eql?(0)
        h[:ended_by_user] = nil
      else
        to_check_user = User.find(ended_by_user_id)
        if to_check_user.is_a?(Parent)
          child = User.find(auth_user_id)
          if to_check_user.parent_of?(child)
            h[:ended_by_user] = to_check_user.as_json({})
          else
            h[:ended_by_user] = nil
          end
        else
          #to_check_user is a child and auth user is a child (send the user name)
          #to_check_user is a child and auth user is a parent (send the user name)
          h[:ended_by_user] = to_check_user.as_more_json({}, auth_user_id)
        end
      end
    end
    h[:comments] = trade_comments.collect(&:as_json)
    h[:waiting_for_counter_offer] = waiting_for_counter_offer?
    h[:waiting_for_meeting_place] = waiting_for_meeting_place?
    h[:waiting_for_parent_approval] = waiting_for_parent_approval_json?
    h[:buyer_agree] = buyer_agree
    h[:seller_agree] = seller_agree
    h[:finished] = completed?
    h[:cancelled] = ended?
    h[:needs_beta_approval] = needs_beta_approval?
    h[:needs_alpha_approval] = needs_alpha_approval?
    h[:alert_level] = alert_level_comparison
    h[:sent_completed_notification] = sent_completed_notification
    h[:completion_confirmed] = completion_confirmed
    h[:buyer_packed] = buyer_packed
    h[:seller_packed] = seller_packed
    h[:completion_confirmed] = completion_confirmed
    h[:information] = {
          coefficients: {
          alpha: ::TradeConstants::ALPHA_COEFF,
          alpha_prime: ::TradeConstants::ALPHA_PRIME_COEFF,
          alpha_approval_required: ::TradeConstants::ALPHA_APPROVAL_REQUIRED,
          beta: ::TradeConstants::BETA_COEFF,
          beta_prime: ::TradeConstants::BETA_PRIME_COEFF,
          beta_approval_required: ::TradeConstants::BETA_APPROVAL_REQUIRED,
      },
        items_in_customers_shop: buyer.item_count,
        items_minimum_threshold: ::TradeConstants::ITEMS_MIN_THRESHOLD,
        items_low_warning_threshold: ::TradeConstants::ITEMS_LOW_WARNING_THRESHOLD
    }
    h
  end

  ##
  # @return <Hash
  #   trade: <self.as_json's content>
  #   needs_action: <boolean> whether this user has awaiting notification that needs action
  #   breathing: <boolean> whether the trade is completed, in breathing mode
  #   title: <String> wording describing the trade status
  #   subtitle: <String> tip on what to do
  # >
  def active_trade_info_for(user, item = nil)
    compare_to_user_id = item.try(:user_id) || ( is_buyer_side?(user) ? buyer_id : seller_id )
    user_notifications = self.notifications.sent_to(compare_to_user_id).not_deleted
    latest_notification = nil
    any_starred = false
    user_notifications.each do|n|
      any_starred = n.starred if not any_starred
      latest_notification = n if n.starred
    end
    latest_notification ||= user_notifications.last
    { trade: self.as_json({}, user.id),
      needs_action: (compare_to_user_id == self.waiting_for_user_id) && any_starred,
      breathing: self.breathing?,
      title: latest_notification.try(item ? :title_for_item : :title_for_trade),
      subtitle: latest_notification.try(item ? :subtitle_for_item : :subtitle_for_trade)
    }
  end

  def items_of_buyer_need_approval?
    unless ::TradeConstants::REQUIRES_PARENT_APPROVAL_FOR_UNEVEN_TRADE
      return false
    end
    buyer_total = items_of(buyer_id).sum{|item| item.price }
    buyer_total > 0.0 && buyer_total >= PARENT_APPROVAL_HIGH_PRICE_THRESHOLD
  end

  def items_of_seller_need_approval?
    unless ::TradeConstants::REQUIRES_PARENT_APPROVAL_FOR_UNEVEN_TRADE
      return false
    end
    seller_total = items_of(seller_id).sum{|item| item.price }
    seller_total > 0.0 && seller_total >= PARENT_APPROVAL_HIGH_PRICE_THRESHOLD
  end

  ##
  # Combo of conditions for both buyer's and seller's sides: trade items match the conditions to require parent's approval,
  # and whether parent already approved.
  def needs_parent_approval?
    # (items_of_buyer_need_approval? && !buyer_parent_approve) || (items_of_seller_need_approval? && !seller_parent_approve) # old simple check by items total price.

    return false if waiting_for_counter_offer?

    comparison = fairness_level_comparison
    if comparison < 0
      !seller_parent_approve
    elsif comparison > 0
      buyer_agree && !buyer_parent_approve # needs buyer to accept first
    else
      false
    end
  end

  # Whether parent needs approval
  # @return <Integer> 0 fair trade close in range or already approved; negative(< 0) seller being beta and wants too little; positive(> 0) seller wants a lot more and buyer being alpha.
  def fairness_level_comparison
    unless ::TradeConstants::REQUIRES_PARENT_APPROVAL_FOR_UNEVEN_TRADE
      return 0
    end
    has_expensive_buyer_item = false
    has_expensive_seller_item = false
    buyer_total = items_of(buyer_id).sum do|item|
      if item.price > PARENT_APPROVAL_HIGH_PRICE_THRESHOLD
        has_expensive_buyer_item = true
      end
      item.price
    end
    seller_total = items_of(seller_id).sum do|item|
      if item.price > PARENT_APPROVAL_HIGH_PRICE_THRESHOLD
        has_expensive_seller_item = true
      end
      item.price
    end
    if buyer_total <= NO_PARENT_APPROVE and seller_total <= NO_PARENT_APPROVE
      0
    else
      if buyer_total < seller_total * BETA_APPROVAL_REQUIRED
        -1 #A is Beta
      elsif has_expensive_seller_item
        -2
      elsif buyer_total > seller_total * ALPHA_APPROVAL_REQUIRED
        1 #B is beta
      elsif has_expensive_buyer_item
        2
      else
        0
      end
    end
  end

  #returns 0 if neither buyer/seller has expensive item
  #1 if buyer has expensive item
  #2 if seller has expensive item
  #3 if both have expensive item

  def who_is_beta
    fairness = fairness_level_comparison
    if fairness < 0
      -1
    elsif fairness > 0
      1
    else
      0
    end
  end

  # @return <Integer> 0 = fair trade close in range; negative(< 0) customer wants lesser, unfair value alert; positive(> 0) seller gets alert of wanting a lot more value.
  #   The specific value of non-zero represents the alert level (1, 2, -1, -2)
  def alert_level_comparison
    unless ::TradeConstants::REQUIRES_PARENT_APPROVAL_FOR_UNEVEN_TRADE
      return 0
    end

    buyer_total = items_of(buyer_id).sum{|item| item.price }
    seller_total = items_of(seller_id).sum{|item| item.price }
    # Round 2 of trade
    if buyer_total < seller_total * BETA_PRIME_COEFF
      -2
    elsif buyer_total < seller_total * BETA_COEFF
      -1

    elsif buyer_total > seller_total * ALPHA_PRIME_COEFF # Round 3 of trade
      2
    elsif buyer_total > seller_total * ALPHA_COEFF # Round 3 of trade
      1
    else
      0
    end
  end

  def decline_but_continue
    #this will be called when B's parent declines the trade but the trade is still allowed to continue.
    wanted_items_map = self.trade_items.where(seller_id: self.seller_id)
    wanted_items_map
  end

  # Use only when needs_parent_approval?
  def needs_beta_approval?
    fairness_level_comparison < 0
  end

  def needs_alpha_approval?
    fairness_level_comparison > 0
  end

  def waiting_for_counter_offer?
    wanted_items_map = self.trade_items.group_by(&:seller_id)
    (wanted_items_map.keys.size < 2) # Waiting for one side to select wanted items
  end

  def both_sides_have_items?
    wanted_items_map = self.trade_items.group_by(&:seller_id)
    wanted_items_map.keys.size == 2
  end

  def waiting_for_meeting_place?
    both_sides_have_items? && !completed?
  end

  ##
  # User has a picked meeting place & time waiting for response
  def has_awaiting_picked_meeting?
    !completed? && self.notifications.last.is_a?(::Users::Notifications::TradePickedMeeting)
  end


  private

  def set_defaults!
    self.status = Status::OPEN if status.blank?
    self.waiting_for_user_id ||= buyer_id
  end
end
