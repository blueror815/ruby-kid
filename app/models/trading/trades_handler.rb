module ::Trading::TradesHandler

  ##
  # Determines the types of messages to send when child selects items for an offer.
  # @current <User> either buyer or seller if not parent approval process

  def create_offer_notification!(current_user, options = {}, reply_method = false, accept = false)
    if waiting_for_counter_offer?
      ::Users::Notifications::TradeNew.create(self, current_user)
      self.notifications.sent_to(current_user.id).update_all(status: ::Users::Notification::Status::DELETED)
      #::Users::Notifications::TradeNew.create(self, the_other_user(current_user), recipient_user_id: current_user.id  )
      self.update_attribute(:waiting_for_user_id, the_other_user(current_user).id )

    else # both sides w/ items
         #
      if not accept
        beta = who_is_beta #-1 is seller beta, 1 is buyer beta
        if items_of_seller_need_approval? and items_of_buyer_need_approval?
          ::Users::Notifications::TradeParentApprovalBuyer.create(self, buyer, { recipient_user_id: self.buyer.parent_id } )
          ::Users::Notifications::TradeParentApprovalSeller.create(self, seller, { recipient_user_id: self.seller.parent_id} )
          ::Users::Notifications::TradeParentBothApproval.create(self, Admin.cubbyshop_admin, { recipient_user_id: self.seller_id })
          ::Users::Notifications::TradeParentBothApproval.create(self, Admin.cubbyshop_admin, { recipient_user_id: self.buyer_id } )
          self.update_attribute(:waiting_for_user_id, 0 )
        elsif beta.eql?(-1) or items_of_seller_need_approval?
          unless seller_parent_approve
            ::Users::Notifications::TradeParentApprovalSeller.create(self, seller, { recipient_user_id: seller.parent_id } )
            ::Users::Notifications::TradeParentApprovalNeededSeller.create(self, Admin.cubbyshop_admin, { recipient_user_id: self.seller_id } )
            self.update_attribute(:waiting_for_user_id, self.seller.parent_id )
          end
        elsif (beta.eql?(1) || items_of_buyer_need_approval?) && seller_agree && buyer_agree
          unless buyer_parent_approve
              ::Users::Notifications::TradeParentApprovalBuyer.create(self, buyer, { recipient_user_id: buyer.parent_id } )
              ::Users::Notifications::TradeParentApprovalNeededBuyer.create(self, Admin.cubbyshop_admin, { recipient_user_id: self.buyer_id } )
              self.update_attribute(:waiting_for_user_id, self.buyer.parent_id )
          end
          else
          if reply_method
            #remove the earlier notification
            ::Users::Notifications::TradeNew.where(recipient_user_id: current_user.id, related_model_id: self.id, sender_user_id: self.buyer.id).delete_all
            self.update_attribute(:waiting_for_user_id, self.buyer.id)
          end
          ::Users::Notifications::TradeReply.where(related_model_type: self.class.to_s, related_model_id: self.id).delete_all
          ::Users::Notifications::TradeAccepted.create(self, current_user)

        end
        self.set_items_with_status!(::Item::Status::TRADING)
      end
    end

  end
  def set_items_with_status!(item_status)
    self.trade_items.each do|trade_item|
      trade_item.item.status = item_status
      trade_item.item.save
    end
  end

  def remove_seller_items!
    seller_items = self.items_of(self.buyer_id)
    denied = []
    seller_items.each do |item|
      item.status = ::Trading::Trade::Status::OPEN
      denied.append(item.id)
      item.save
    end
    to_delete = self.trade_items.where(seller_id: self.seller_id)
    to_delete.each do |del|
      del.destroy
    end
    self.add_denied(denied)
  end


  # +items+ <Item> or <Array of Item> optional. If specified, adds the item to bundle if needed
  # +quantities_map+ <Hash of item_id => quantity wanted> optional.  These should correspond to those +items+.
  # @return <Trading::TradeComment>

  def create_comment_from_user!(author, trade_comment, items = [], quantities_map = {})
    unless active?
      self.errors.add(:status, 'Cannot make offer to a closed trade')
      return false
    end
    items = [items] if items && items.is_a?(Item)

    trade_items_map = self.trade_items.group_by(&:seller_id)
    the_other_user = self.the_other_user(author)
    #logger.info "    .. the other user (#{the_other_user.id}) wants #{trade_items_map[author.id].to_a.size} items"
    self.set_user_agree(author) if trade_items_map[author.id].present? # agrees to the other side's items

    trade_item_update_count = 0 # how many trade items have changed

    if items.present?

      self.save if changed?

      existing_ids = self.trade_items.collect(&:item_id)
      items.each do |item|
        unless existing_ids.include?(item.id)
          trade_item_update_count += 1
          self.trade_items << ::Trading::TradeItem.create(trade_id: self.id, item_id: item.id, seller_id: item.user_id, quantity: quantities_map[item.id] || 1)
        end
      end
      self.reload
      delete_items_from_cart!(author, items)

    end


    #self.status = (bundle_items_map.size == 2 && trade_item_update_count > 0) ? ::Trading::Trade::Status::PENDING : ::Trading::Trade::Status::PENDING
    if trade_item_update_count > 0 && self.user_agree?(author)
      self.status =  ::Trading::Trade::Status::PENDING
    else
      self.status = ::Trading::Trade::Status::OPEN
    end
    logger.info "  User #{author.user_name} wants #{items.size} items, #{trade_item_update_count} changed | buyer_agree? #{self.buyer_agree} | seller_agree? #{self.seller_agree} | status #{self.status}"

    self.save

    trade_comment.trade_id = self.id
    trade_comment.item_id = items.try(:first).try(:id)
    trade_comment.user_id = author.id
    trade_comment.save

    trade_comment
  end

  def delete_items_from_cart!(buyer, items)
    ::Carts::CartItem.delete_all(["user_id = ? AND item_id IN (?)", buyer.id, items.collect(&:id)])
  end


  ##
  # Marks the bundle with one user's agreement. By going through offer responses, if this agreement is side A's
  # response and side A does not want any items of side B, the trade would be finalized.  Else if side A does want
  # some of side B's items, the status will be pending so in wait for the other side's agreement.  Therefore, if both sides
  # want items from each other, both need to respond with agreements in order to finalize.
  # +options+ <Hash>
  #   :comment - Additional words to the offer acceptance.
  # @return <Boolean> whether the trade is accepted with both side's agreement.
  def agree_to_offer!(user, options = {})
    if completed?
      self.errors.add(:status, 'Cannot accept offer of a closed trade.')
      return false
    end
    passing_flags = {buyer_id => false, seller_id => false}
    return [false, false] if items.count.zero?

    if user.is_a?(Parent)

      ::Trading::TradesParentHandler.approve_offer!(self, user, options )

    else # Child =================

      accept_offer_trade_update!(user, options )
    end

    passing_flags[buyer_id] = items_of(buyer_id).blank? || buyer_agree
    passing_flags[seller_id] = items_of(seller_id).blank? || seller_agree
    passing_flags
  end
  alias_method :accept_offer!, :agree_to_offer!


  ##
  # This would set the status to COMPLETED, so means both users can exchange info for payments and shipping.
  def finalize!
    self.status = ::Trading::Trade::Status::COMPLETED
    self.completed_at = DateTime.now
    self.waiting_for_user_id = 0
    self.save
    # Users::Notification.where(related_model_type: self.class.to_s, related_model_id: self.id ).update_all(status: ::Users::Notification::Status::DELETED)
  end

  ##
  # Different from end_offer! by simply ignoring current offer without considering user.
  def decline_offer!(user, options = {})
    modify_offer!(user, ::Trading::Trade::Status::REMOVED, ::Trading::TradeComment::Status::REPLIED, ::Trading::TradeComment::Status::DECLINED,
                  ::Users::Notification::Status::DELETED )
    ::Users::Notifications::TradeDeclined.create(self, user)

    self.set_items_with_status!(::Item::Status::OPEN)

    if needs_parent_approval? && user.is_a?(Parent)
      ::Trading::TradesParentHandler.end_offer!(self, user, options )
    end

    ::Users::Notifications::TradeEnded.create(self, user)
  end

  # This and other waiting offer responses would set the status to REPLIED, so offers can no longer be made. Will insert
  # an entry of trade ended/cancelled.
  def end_offer!(user, continue = nil, options = {})

    if not sent_completed_notification
      if user.is_a?(Child) and ((items_of_buyer_need_approval? and buyer_parent_approve) or (items_of_seller_need_approval? and seller_parent_approve))
        #this is the condition where the child ends the trade after getting parent approval.
        ::Users::Notifications::TradeEnded.create(self, user, options.merge(recipient_user_id: self.the_other_user(user).id))
        modify_offer!(user, ::Trading::Trade::Status::ENDED, ::Trading::TradeComment::Status::REPLIED, ::Trading::TradeComment::Status::DECLINED,
                            ::Users::Notification::Status::DELETED)
        self.set_items_with_status!(::Item::Status::OPEN)
      elsif not items_of_buyer_need_approval? and not items_of_seller_need_approval?
        if user.is_a?(Parent)
          #figure out which parent declined.
          if self.is_seller_side?(user)
            #seller side denial from a parent means the trade continues.
            modify_offer!(user, ::Trading::Trade::Status::PENDING, ::Trading::TradeComment::Status::REPLIED,::Trading::TradeComment::Status::DECLINED,
                                ::Users::Notification::Status::DELETED)
            ::Users::Notifications::TradeParentNotApprovedCont.create(self, user, options.merge(recipient_user_id: self.seller_id)) #is seller is last boolean
            self.remove_seller_items!
            #now will just allow user to reply again?
          else #buyer side
            #trade ends.
            modify_offer!(user, ::Trading::Trade::Status::ENDED, ::Trading::TradeComment::Status::REPLIED, ::Trading::TradeComment::Status::DECLINED,
                                ::Users::Notification::Status::DELETED)
            ::Users::Notifications::TradeParentNotApproved.create(self, user, options.merge(recipient_user_id: self.buyer_id)) #send true for buyer side.
            ::Users::Notifications::TradeParentNotApproved.create(self, Admin.cubbyshop_admin, options.merge(recipient_user_id: self.seller_id))
            self.set_items_with_status!(::Item::Status::OPEN)
          end
        else #it's a child.
          #user declined the trade. So automatically end it.
          #this will not be the seller side, because they have their own path to decline.
          #this will always be the buyer side.
          if continue and self.is_buyer_side?(user)
            modify_offer!(user, ::Trading::Trade::Status::PENDING, ::Trading::TradeComment::Status::REPLIED, ::Trading::TradeComment::Status::DECLINED,
                                ::Users::Notification::Status::DELETED)
            ::Users::Notifications::TradePickSomethingElse.create(self, user) #forces the user to call reply again
            self.remove_seller_items!
            self.waiting_for_user_id = self.seller_id
            self.save
          else
            modify_offer!(user, ::Trading::Trade::Status::ENDED, ::Trading::TradeComment::Status::REPLIED, ::Trading::TradeComment::Status::DECLINED,
                              ::Users::Notification::Status::DELETED)
            self.set_items_with_status!(::Item::Status::OPEN)
            other_user_id = self.the_other_user(user).id
            ::Users::Notifications::TradeEnded.create(self, user, options.merge(recipient_user_id: other_user_id))
          end
        end
      elsif not waiting_for_counter_offer?
        #TRADE ENDS. if either deny, it just means that the trade will end altogether.
        modify_offer!(user, ::Trading::Trade::Status::ENDED, ::Trading::TradeComment::Status::REPLIED, ::Trading::TradeComment::Status::TRADE_REMOVED,
                            ::Users::Notification::Status::DELETED)
        #have to account for the different potential senders within the trade.
        if user.parent_of?(self.buyer)
          sender_buyer = user
          sender_seller = Admin.cubbyshop_admin
        else
          sender_seller = user
          sender_buyer = Admin.cubbyshop_admin
        end
        ::Users::Notifications::TradeParentNotApproved.create(self, sender_seller, options.merge(recipient_user_id: self.seller.id)) #send true for buyer side.
        ::Users::Notifications::TradeParentNotApproved.create(self, sender_buyer, options.merge(recipient_user_id: self.buyer.id))
        self.set_items_with_status!(::Item::Status::OPEN)
      else
        modify_offer!(user, ::Trading::Trade::Status::ENDED, ::Trading::TradeComment::Status::REPLIED, ::Trading::TradeComment::Status::DECLINED,
                          ::Users::Notification::Status::DELETED)

        ::Users::Notifications::TradeDeclined.create(self, user)
        self.set_items_with_status!(::Item::Status::OPEN)
      end
    else
      #Last notification was trade_completed_check
      modify_offer!(user, ::Trading::Trade::Status::ENDED, ::Trading::TradeComment::Status::REPLIED, ::Trading::TradeComment::Status::DECLINED,
                        ::Users::Notification::Status::DELETED)
      ::Users::Notifications::TradeEnded.create(self, user, options.merge(recipient_user_id: self.the_other_user(user).id))
      self.ended_by_user_id = 0 #so it says "This trade has been ended"
      self.set_items_with_status!(::Item::Status::OPEN)
    end
  end




    #modify_offer!(user, ::Trading::Trade::Status::ENDED, ::Trading::TradeComment::Status::REPLIED, ::Trading::TradeComment::Status::TRADE_ENDED,
    #               Users::Notification::Status::DELETED )

    #if needs_parent_approval? && user.is_a?(Parent)
      #if the parent denies the trade, then
    #  ::Trading::TradesParentHandler.end_offer!(self, user, options )

    #else
      #if the user ends the trade, then the trade is definitely straight up over.
    #  ::Users::Notifications::TradeEnded.create(self, user, options )
    #end

    #self.set_items_with_status!(::Item::Status::OPEN)
  #end

  # Admin command to end the offer.
  def remove_offer!(admin_user)
    modify_offer!(admin_user, ::Trading::Trade::Status::REMOVED, ::Trading::TradeComment::Status::REPLIED, ::Trading::TradeComment::Status::TRADE_REMOVED,
                  ::Users::Notification::Status::DELETED)
    self.set_items_with_status!(::Item::Status::OPEN)
  end

  def pick_meeting!(current_user, comment)
    self.trade_comments << ::Trading::TradeComment.new(status: ::Trading::TradeComment::Status::REPLIED,
                                                       user_id: current_user.id, comment: comment, is_meeting_place: true )
    logger.info "| Trade #{self.id} - User #{current_user.id} picking meeting: #{comment}"

    if self.status != ::Trading::Trade::Status::ACCEPTED
      if self.is_buyer_side?(current_user)
        self.buyer_agree = true # regardless
      end
      self.status = ::Trading::Trade::Status::ACCEPTED
      self.set_items_with_status!(::Item::Status::TRADING)
    end

    self.waiting_for_user_id = the_other_user(current_user).id
    self.last_meeting_place_set_by = current_user.id
    self.save

    #I think I can remove the first "TradePickedMeetingSent" message?
    Users::Notifications::TradePickedMeetingSent.create(self, self.the_other_user(current_user) )
    Users::Notifications::TradePickedMeeting.create(self, current_user)

    ::Jobs::StatsRecalculation.new(buyer_id).enqueue!
    ::Jobs::StatsRecalculation.new(seller_id).enqueue!

  end

  MEETING_RESPONSE_ACTION_AGREE = 'AGREE'
  MEETING_RESPONSE_ACTION_CHANGE = 'CHANGE'

  def respond_to_meeting!(current_user, action = nil, comment = nil)
    status = nil
    the_other_user = self.the_other_user(current_user)
    if (action.to_s.upcase == MEETING_RESPONSE_ACTION_AGREE)
      self.status = ::Trading::Trade::Status::COMPLETED
      status = ::Trading::TradeComment::Status::AGREED

      # Delete all old messages
      self.notifications.not_deleted.update_all(status: ::Users::Notification::Status::DELETED)

      ::Users::Notifications::TradeMeetingAgreed.create(self, current_user)
      ::Users::Notifications::TradeMeetingAgreed.create(self, the_other_user)
      #the other user is the buyer. So the recipient is set to the seller.
      #the other user should refer to the seller

    else
      status = ::Trading::TradeComment::Status::DISAGREED
      self.last_meeting_place_set_by = current_user.id
      self.notifications.not_deleted.update_all(status: ::Users::Notification::Status::DELETED)
      #current user will be the seller, so just send it as the other user
      ::Users::Notifications::TradeChangeMeeting.create(self, current_user)
    end
    self.trade_comments << ::Trading::TradeComment.new(status: status, user_id: current_user.id, comment: comment, is_meeting_place: true )
    self.waiting_for_user_id = the_other_user(current_user).id
    self.save

    if self.completed?
      self.finalize!
    end

  end

  def reason_for_end!(reason_param, ended_user_id, other_reason = nil)
    if reason_param.present?
      self.reason_ended = reason_param.downcase.to_sym
    end
    if self.reason_ended.eql? :other and other_reason.present?
      self.other_reason = other_reason
    end
    self.ended_by_user_id = ended_user_id
    self.save
  end

  def confirm_completion!(current_user, completion_confirmed_value)
    self.notifications.to_a.each do|n|
      if n.is_a?(::Users::Notifications::TradeCompletedCheck)
        n.update_attribute(:status, n.class::Status::DELETED)
      end
    end
    if completion_confirmed_value
      logger.debug "========= Trade b/w #{self.buyer_id} and #{self.seller_id} - Confirm Completion.\n .. Ending items"
      self.set_items_with_status!(::Item::Status::ENDED)

      self.waiting_for_user_id = 0
      self.completion_confirmed = completion_confirmed_value
      ::Users::Notifications::TradeFromPast.create(self, Admin.cubbyshop_admin, {recipient_user_id: self.buyer_id})
      ::Users::Notifications::TradeFromPast.create(self, Admin.cubbyshop_admin, {recipient_user_id: self.seller_id})
      self.save
    else
      self.waiting_for_user_id = 0 #this will be set once the trade completedcheck message is sent out again
      self.completion_confirmed = completion_confirmed_value
      self.completed_at = DateTime.now
      self.sent_completed_notification = false
      self.save
    end
  end

  #buyer is true
  #seller is false
  def packed!(buyer, auth_user_id)
    note = self.notifications.where(recipient_user_id: auth_user_id).last
    if buyer
      self.buyer_packed = true
      note.status = ::Users::Notification::Status::DELETED
      note.save
    else
      self.seller_packed = true
      note.status = ::Users::Notification::Status::DELETED
      note.save
    end
    self.save
  end

  protected

  # Common operation to set a bundle offer to status, same status to waiting offer responses and add new entry to list.
  # +new_status+ <String> optinal.  Status value for Offers::OfferBundle
  # +change_to_trade_comment_status+ <String> optional.  Status value for Trading::TradeComment
  # +new_trade_comment_status+ <String> optional.  Status value for Trading::TradeComment
  # +change_notifications_to_status+ <String> optiona.  Status of Users::Notifications of this trade changed to

  def modify_offer!(user, new_status = nil, change_to_trade_comment_status = nil, new_trade_comment_status= nil, change_notifications_to_status = nil, options = {})
    self.attributes = {:status => new_status} if new_status.present?
    if new_trade_comment_status.present?
      self.trade_comments << ::Trading::TradeComment.new(user_id: user.id, status: new_trade_comment_status, comment: options[:comment]  )
    end
    self.save
    if change_notifications_to_status.present?
      self.notifications.update_all(status: change_notifications_to_status )
    end
    self.trade_comments.waiting.each { |o|
      o.update_attribute(:status, change_to_trade_comment_status) } if change_to_trade_comment_status.present?
  end

  def accept_offer_trade_update!(user, options = {})
    is_user_buyer = self.is_buyer_side?(user)

    logger.info "=> Child (#{user.user_name}) of #{is_user_buyer ? 'buyer' : 'seller'} accepts offer.  still needs approval? #{self.needs_parent_approval?}"
    self.attributes = {:buyer_agree => true}
    self.waiting_for_user_id = buyer_id

    self.status = (buyer_agree && seller_agree && !needs_parent_approval? ) ? ::Trading::Trade::Status::ACCEPTED : ::Trading::Trade::Status::PENDING
    self.trade_comments << ::Trading::TradeComment.new(status: ::Trading::TradeComment::Status::ACCEPTED,
                                                       user_id: user.id, comment: options[:comment] )
    self.save

    create_offer_notification!( user, options, false, false )

    ::Stores::Following.where("user_id = ? OR user_id = ?", buyer_id, seller_id ).update_all( last_traded_at: Time.now )

  end


end
