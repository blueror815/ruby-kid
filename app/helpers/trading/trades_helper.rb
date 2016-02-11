module Trading
  module TradesHelper

    ##
    # Sets the list of Item with active_trade <Trading::Trade> and active_trade_json <Hash>
    # Arguments:
    #   items <Array of Item>
    #   user <User> The user that is checked whether involved in trade and needs action.  If not specified, item owner would be used.
    # ==============
    # If item is within a trade, its attribute active_trade would be set with a hash of
    #   trade: <Hash> JSON of Trading::Trade
    #   needs_action: <boolean> whether this user has awaiting notification that needs action
    #   breathing: <boolean> whether the trade is completed, in breathing mode
    #   title: <String> wording describing the trade status
    #   subtitle: <String> tip on what to do


    #always called by user_controller "dashboard"
    #corresponds to user dashboard
    def set_with_trading_info!(items, user = nil, trades_or_user)
      return if items.blank?
      user ||= items.first.user
      items_to_trades = {}
      items_to_buy_requests = {}
      trade_ids = []
      ::Trading::TradeItem.where(item_id: items.collect(&:id) ).includes(:trade).each do|trade_item|
        items_to_trades[trade_item.item_id] = trade_item.trade
        trade_ids << trade_item.trade_id
      end
      ::Trading::BuyRequestItem.where(item_id: items.collect(&:id) ).includes(:buy_request).each do|br_item|
        logger.info "   #{br_item.as_json} | item_id #{br_item.buy_request}"
        items_to_buy_requests[br_item.item_id] = br_item.buy_request
      end
      trades_to_notes = ::Users::Notification.where(related_model_type:'Trading::Trade', related_model_id: trade_ids.uniq ).sent_to(user.id).group_by(&:related_model_id)
      items.each do|item|
        invited = false
        test_for_invite_or_end = ::Trading::TradeItem.where(seller_id: user.id, item_id: item.id)
        if (not test_for_invite_or_end.empty?) and item.status.eql? ::Item::Status::OPEN and test_for_invite_or_end.last.trade.ended_by_user_id.eql? 0
          #can't return if the user is a parent.
          invited = true
          status = test_for_invite_or_end.last
          if status.eql? ::Trading::Trade::Status::REMOVED or status.eql? ::Trading::Trade::Status::ENDED
            invited = false
          end
        end

        next if !item.trading? && !item.buying? && !invited

        ##################### BuyRequest
        #
        if (buy_request = items_to_buy_requests[item.id] )
          logger.info "-------| Item #{item.id} has BuyRequest#{buy_request}"
          item.active_buy_request = buy_request

        ##################### Trade
        #
        elsif (trade = items_to_trades[item.id] )
          user_notifications = trades_to_notes[trade.id] || []
          latest_notification = nil
          any_starred = false
          user_notifications.each do |n|
            any_starred = n.starred if not any_starred
            latest_notification = n if n.starred
          end
          latest_notification = trade.notifications.last
          if not latest_notification.class.to_s.eql? "Users::Notifications::TradeEnded"
            #needs_action = (user.id == trade.waiting_for_user_id || trade.completed?) && any_starred # when completed both sides are waited
            #changed this because trades don't need
            #or

            item.active_trade = trade
            if latest_notification.nil?
              title = ""
              tip = ""
            else
              not_packed = false
              if trade.is_seller_side?(user)
                if not trade.seller_packed
                  not_packed = true
                end
                title = latest_notification.title_for_item_b
                tip = latest_notification.tip_for_item_b
                #puts '-' * 10
                #puts latest_notification.title
                #puts latest_notification.tip
                #puts item.id
                #puts title
                #puts tip
                #puts '-' * 10
              else
                if not trade.buyer_packed
                  not_packed = true
                end
                title = latest_notification.title_for_item
                tip = latest_notification.subtitle_for_item
                #puts '-' * 10
                #puts latest_notification.title
                #puts item.id
                #puts title
                #puts tip
                #puts '-' * 10
              end
            end
            needs_action = (user.id == trade.waiting_for_user_id) or not_packed
            item.active_trade_json = {
                trade: trade.as_json({}, trade.the_other_user(user.id)),
                needs_action: needs_action,
                breathing: trade.breathing?,
                title: title,
                subtitle: tip
            }
          end
          #active_trade_h = item.active_trade_json
          #logger.info "-----| %5d | trading_status %2d | needs_action? %5s | breathing? %5s | %s | %s" %
          #                      [ item.id, active_trade_h.try(:[], :trading_status).to_i, active_trade_h.try(:[], :needs_action), active_trade_h.try(:[], :breathing), active_trade_h.try(:[], :title), active_trade_h.try(:[], :subtitle) ]
        end
      end
    end

    ## Always called by trades Controller "index"
    #corresponds to Trade dashboard
    # @return <Array of Item, with active_trade and active_trade_json set the same as in set_with_trading_info!
    def fetch_trading_items(trades, user, trades_or_user, parent = false)
      return [] if trades.blank?

      trades_to_notes = ::Users::Notification.where(related_model_type:'Trading::Trade', related_model_id: trades.collect(&:id) ).sent_to(user.id).group_by(&:related_model_id)
      results = trades.collect do|trade|
        user_notifications = trades_to_notes[trade.id] || []
        latest_notification = nil
        any_starred = false
        user_notifications.each do|n|
          any_starred = n.starred if not any_starred
          latest_notification = n if n.starred
        end

        latest_notification = trade.notifications.last
        item = trade.items_of(trade.the_other_user(user).id).first
        invited = false
        completed_note = false
        if item
          if (not ::Trading::TradeItem.where(seller_id: trade.the_other_user(user).id, item_id: item.id).empty?) and item.status.eql? ::Item::Status::OPEN
            invited = true
          end
          if trade.status.eql? "COMPLETED" and trade.completion_confirmed
            completed_note = true
          end
          if item.status.eql?(::Item::Status::TRADING) or invited or completed_note
            item.active_trade = trade
            if latest_notification.nil?
              unless completed_note
                title = ''
                tip = ''
              end
            else
              if not parent and not user.is_a?(Parent)
                not_packed = false
                if trade.is_seller_side?(user)
                  if not trade.seller_packed
                    not_packed = true
                  end
                  title = latest_notification.title_for_trade_b
                  tip = latest_notification.tip_for_trade_b
                else
                  if not trade.buyer_packed
                    not_packed = true
                  end
                  title = latest_notification.title_for_trade
                  tip = latest_notification.subtitle_for_trade
                end
              else
                title = latest_notification.title_for_parent
                tip = latest_notification.tip_for_parent
              end
              needs_action = (user.id == trade.waiting_for_user_id) or not_packed
            end
            item.active_trade_json = {
                trade: trade.as_json({}, trade.the_other_user(user.id) ),
                needs_action: needs_action,
                breathing: trade.breathing?,
                title: title,
                subtitle: tip
            }
            #active_trade_h = item.active_trade_json
            #logger.info "-----| %5d | trade status %8s | needs_action? %5s | breathing? %5s | %s | %s" %
            #                      [ item.id, trade.try(:status), active_trade_h.try(:[], :needs_action), active_trade_h.try(:[], :breathing), active_trade_h.try(:[], :title), active_trade_h.try(:[], :subtitle) ]
          else
            item.active_trade = nil
          end
        end
        item
      end
      results.compact
    end

    ##
    # View helpers

    ##
    # Pick which user of the trade presented first according to viewer's relationship.
    # trade <Trading::Trade>
    # viewer <User> If nil, would be the current user
    def ordered_users_list(trade, viewer = nil)
      viewer ||= auth_user
      users = []
      if viewer.id == trade.buyer_id
        users << trade.seller
        users << trade.buyer
      else
        users << trade.buyer
        users << trade.seller
      end
      users
    end

  end
end
