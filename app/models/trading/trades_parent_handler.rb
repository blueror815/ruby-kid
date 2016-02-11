##
# Functions of how a parent handles trading actions.  So passed on user should be a parent.
module Trading
  class TradesParentHandler


    def self.approve_offer!(trade, user, options= {})
      if trade.items_of_buyer_need_approval? and trade.items_of_seller_need_approval?
        if trade.is_seller_side?(user)
          trade.seller_parent_approve = true
          ::Users::Notifications::TradeParentApprovalSeller.sent_to(user.id).
            where(related_model_type: trade.class.to_s, related_model_id: trade.id ).
            update_all(status: ::Users::Notification::Status::DELETED)
        else
          trade.buyer_parent_approve = true
          ::Users::Notifications::TradeParentApprovalBuyer.sent_to(user.id).
            where(related_model_type: trade.class.to_s, related_model_id: trade.id ).
            update_all(status: ::Users::Notification::Status::DELETED)
        end
        if trade.both_exp_approved?
          #create TradeApproved for both.
          ::Users::Notifications::TradeParentApprovalNeeded.sent_to(trade.seller_id).where(related_model_id: trade.id).update_all(status: ::Users::Notification::Status::DELETED)
          ::Users::Notifications::TradeParentApprovalNeeded.sent_to(trade.buyer_id).where(related_model_id: trade.id).update_all(status: ::Users::Notification::Status::DELETED)
          ::Users::Notifications::TradeApprovedSeller.create(trade, trade.seller.parent, {recipient_user_id: trade.seller_id}) if trade.seller.should_contact_parent?
          ::Users::Notifications::TradeApprovedBuyer.create(trade, trade.buyer.parents.first, {recipient_user_id: trade.buyer_id}) if trade.buyer.should_contact_parent?
          trade.status = (trade.buyer_agree && trade.seller_agree) ? ::Trading::Trade::Status::ACCEPTED : ::Trading::Trade::Status::PENDING
          trade.waiting_for_user_id = trade.buyer_id
        end
        trade.save
      else
        #normal case where they needed approval for non_exp thing.
        is_user_buyer = trade.is_buyer_side?(user)
        trade.attributes = { (is_user_buyer ? :buyer_parent_approve : :seller_parent_approve) => true}
        trade.waiting_for_user_id = trade.buyer_id
        trade.status = (trade.buyer_agree && trade.seller_agree) ? ::Trading::Trade::Status::ACCEPTED : ::Trading::Trade::Status::PENDING
        trade.save
        puts "=> Parent (#{user.user_name}) of #{is_user_buyer ? 'buyer' : 'seller'} accepts offer.  Trade status #{trade.status}, still needs approval? #{trade.needs_parent_approval?}"
        if is_user_buyer
          ::Users::Notifications::TradeParentApprovalBuyer.sent_to(user.id).
            where(related_model_type: trade.class.to_s, related_model_id: trade.id ).
            update_all(status: ::Users::Notification::Status::DELETED)
          ::Users::Notifications::TradeApprovedBuyer.create(trade, user, {recipient_user_id: trade.buyer_id})
        else
          ::Users::Notifications::TradeParentApprovalSeller.sent_to(user.id).
            where(related_model_type: trade.class.to_s, related_model_id: trade.id ).
            update_all(status: ::Users::Notification::Status::DELETED)
          ::Users::Notifications::TradeApprovedSeller.create(trade, user, {recipient_user_id: trade.seller_id})
          ::Users::Notifications::TradeAccepted.create(trade, trade.seller)
        end
      end
    end

    def self.end_offer!(trade, user, options = {})

      # Remove parent approval
      ::Users::Notifications::TradeParentApprovalSeller.sent_to(user.id).
        where(related_model_type: trade.class.to_s, related_model_id: trade.id ).
        update_all(status: ::Users::Notification::Status::DELETED)
      ::Users::Notifications::TradeParentApprovalBuyer.sent_to(user.id).
        where(related_model_type: trade.class.to_s, related_model_id: trade.id ).
        update_all(status: ::Users::Notification::Status::DELETED)

      #Instead of creating a blanket "TradeNotApproved", create a different notification depending on who it is going too.
      #find out why it was not approved.
      #user is going to be the parent.
      #figure out the state.
      if trade.items_of_buyer_need_approval? and trade.items_of_seller_need_approval?
        #say that the trade was not approved. Sender is from cubbyshop_admin
        ::Users::Notifications::TradeParentNotApproved.create(trade, Admin.cubbyshop_admin, options.merge(recipient_user_id: trade.buyer_id))
        ::Users::Notifications::TradeParentNotApproved.create(trade, Admin.cubbyshop_admin, options.merge(recipient_user_id: trade.seller_id))
        #delete the other user's tradeParentApproval message.
        other_user = trade.the_other_user(user) # this gives the kid. Get parent.
        ::Users::Notifications::TradeParentApproval.sent_to(other_user.parent_id).
          where(related_model_type: trade.class.to_s, related_model_id: trade.id).
          update_all(status: ::Users::Notification::Status::DELETED)

        trade.set_all_items_status!(Item::Status::OPEN)
        trade.status = ::Trading::Trade::Status::ENDED
      else
        #normal beta, send out trade not approved to both.
        #IF the disapproval is from the buyer then end the trade, otherwise, it's cotinue.
        if trade.is_seller_side?(user)
          ::Users::Notifications::TradeParentNotApprovedCont.create(trade, user, options.merge(recipient_user_id: trade.seller_id))
          trade.remove_seller_items!
          trade.status = ::Trading::Trade::Status::PENDING
          trade.status = ::Trading::Trade::Status::ENDED
          #trade.set_items_with_status!(Item::Status::OPEN)
          #remove seller items from trade.
        else
          #trade is buyer side, and first notification is already deleted.
          #::Users::Notifications::TradeParentNotApproved.create(trade, user, options.merge(recipient_user_id: trade.waiting_for_user_id) )
          #::Users::Notifications::TradeParentNotApproved.create(trade, Admin.cubbyshop_admin,
          #                                                      options.merge(recipient_user_id: trade.the_other_user(trade.waiting_for_user_id).id ) )
          if user.parent_of?(self.buyer)
            sender_buyer = user
            sender_seller = Admin.cubbyshop_admin
          else
            sender_seller = user
            sender_buyer = Admin.cubbyshop_admin
          end

          ::Users::Notifications::TradeParentNotApprovedSeller.create(trade, sender_seller, options.merge(recipient_user_id: self.seller.id)) #send true for buyer side.
          ::Users::Notifications::TradeParentNotApprovedBuyer.create(trade, sender_buyer, options.merge(recipient_user_id: self.buyer.id))

          trade.status = ::Trading::Trade::Status::ENDED
          trade.set_items_with_status!(Item::Status::OPEN)
        end
      end
      trade.save

    end
  end
end
