##
# Each TradeComment is tied to an Item (actually OfferBundle of Items), so :item_id parameter should be given
# except update and destroy

module Trading
  class TradesController < ApplicationController

    include ::Trading::ControllerHelper
    include ::Trading::TradesHelper
    include ::Users::UserInfo

    helper :items

    before_filter :find_current_trade, except: [:new, :index, :show_eligibility]
    before_filter :find_current_items, only: [:create, :reply]

    def new

    end

    def show
      eligible, reason = check_user_eligibility
      if not @trade.nil?

        @page_title = @menu_title = 'Approve Trade' if auth_user.is_a?(Parent) && @trade.active?

        h = @trade.as_json({}, auth_user.id)
        h.merge!(make_json_status_hash(eligible, eligible) )
        respond_to do |format|
          format.html { render 'trading/trades/show', layout:'layouts/markup' }
          format.json { render json: h }
        end
      else
        respond_to do |format|
          format.html { render 'trading/trades/show', layout:'layouts/markup' }
          format.json {
            render status: 404,
            json: []
          }
        end
      end
    end

    def index
      @page_title = @menu_title = 'My Trades'

      @trades = ::Trading::Trade.for_user(auth_user).not_deleted.includes(:trade_items)

      ActiveSupport::Notifications.instrument('process.trades.fetch_trading_items', :name => auth_user.user_name) do
        @items = fetch_trading_items(@trades, auth_user, true)
      end
      sort_params = {}

      ActiveSupport::Notifications.instrument('process.trades.sort_items', :name => auth_user.user_name) do
        if params[:include_favorite_counts]
          @favorite_counts = ::Items::FavoriteItem.make_favorite_counts_map(@items.collect(&:id))
          sort_params[:favorite_counts] = @favorite_counts
        end

        @items.sort! do|x, y|
          y.trading_sort_priority(sort_params, auth_user.id) <=> x.trading_sort_priority(sort_params, auth_user.id)
        end
      end
      @result = @items.map {|i| i.as_json({}, auth_user.id)}

      respond_to do |format|
        format.html
        format.json { render json: @result }
      end
    end

    #this will only take in completed = true/false
    #if they're ending it
    def completed
      trade = ::Trading::Trade.where(id: params[:id]).first
      if trade.sent_completed_notification
        if params[:completed].eql? "false"
          trade.confirm_completion!(auth_user, false)
        else
          trade.confirm_completion!(auth_user, true)
        end
        respond_to do |format|
          format.json {
            render json: {
              trade: @trade,
            }
          }
        end
      else
        respond_to do |format|
          format.json {
            render status: 412,
            json: {
              trade: @trade
            }
          }
        end
      end
    end

    def trade_completed
      #params are id and auth_user
      trade = ::Trading::Trade.where(id: params[:id]).first
      #if this was completed, the last notification is the one we want to delete.
      to_delete_note = trade.notifications.where(type: "Users::Notifications::TradeCompletedCheck").first
      if to_delete_note.nil?
        respond_to do |format|
          format.json {
            render json: {
              trade: @trade,
              deleted: false
            }
          }
        end
      else
        to_delete_note.destroy
        trade.confirm_completion!(auth_user, true)
        if trade.save
          respond_to do |format|
            format.json {
              render json: {
                trade: @trade,
                deleted: true
              }
            }
          end
        end
      end
    end

    def reply

      @trade.add_items_to_trade!(auth_user, @items)

      #if @trade.is_buyer_side?(auth_user)
      #  ::Users::Notification.sent_to(@trade.seller_id).where(related_model_id: @trade.id).update_all(status: ::Users::Notification::Status::DELETED)
      #end

      @needs_approval = @trade.needs_parent_approval?
      if @needs_approval
        @reason = "One of the items if over 50 dollars"
      else
        @reason = "None"
      end

      if params[:comment].present?
        @trade_comment = ::Trading::TradeComment.new(user_id: auth_user.id, comment: params[:comment], price: params[:price])
        @trade.trade_comments << @trade_comment
      end

      if @trade.save

        respond_to do |format|
          format.json {
            render json: {
              trade: @trade,
              success: true,
              is_eligible: true,
              needs_parent_approval: @needs_approval,
              reason: @reason
            }
          }
          format.html {
            redirect_with_success && return
          }
        end

      else
        flash[:error] = @trade.errors.values.join('. ') if flash[:error].blank?
        logger.info "| Errors: #{flash[:error]}"
        logger.info "| Reason: #{flash[:reason]}"
        format.json { render json: make_json_status_hash(false, eligble) }
        format.html { redirect_to((@trade.new_record ? new_trade_path(params) : trade_path(@trade))) && return }
      end
    end

    # Parameters:
    #   :item_id <Integer> or <Array of Integers>  Multiple items together may be packed into one bundle.
    #      When only params[:item_id] is given, search for first bundle that includes the item.
    def create

      @trade ||= ::Trading::Trade.new(buyer_id: auth_user.id, seller_id: @items.first.user_id)

      eligible, reason = check_user_eligibility
      if eligible

        @trade.add_items_to_trade!(auth_user, @items)

        if params[:comment].present?
          @trade_comment = ::Trading::TradeComment.new(user_id: auth_user.id, comment: params[:comment], price: params[:price])
          @trade.trade_comments << @trade_comment
        end
      end

      #quantities_map = parse_quantities_map
      if eligible && @trade.save

        respond_to do |format|
          format.json { render json: {trade: @trade.as_json({}, auth_user.id),
                                      success: true,
                                      is_eligible: eligible
          }
          }
          format.html { redirect_with_success && return }
        end

      else
        flash[:error] = @trade.errors.values.join('.  ') if flash[:error].blank?
        logger.info "| Errors: #{flash[:error]}"
        logger.info "| Reason: #{flash[:reason]}"
        respond_to do |format|
          format.json { render json: make_json_status_hash(false, eligible) }
          format.html { redirect_to((@trade.new_record? ? new_trade_path(params) : trade_path(@trade))) && return }
        end

      end

    end

    ##
    # Specific API method to list out a trade's comments
    def list_comments
      respond_to do |format|
        format.json { render json: @trade.trade_comments }
      end
    end

    ##
    # Add comment to the trade
    # Required parameters: id, comment
    #
    def comments

      @trade_comment = nil
      if params[:comment].present?
        @trade_comment = ::Trading::TradeComment.new(user_id: auth_user.id, comment: params[:comment], price: params[:price])

        @trade.trade_comments << @trade_comment
        @trade.save

        # Check whether
        last_n = @trade.notifications.where(recipient_user_id: @trade.the_other_user(auth_user).id).not_deleted.last
        if last_n && last_n.starred
          last_n.add_additional_action!('trade_comment', @trade_comment.id)
        end

        @last_comment = @trade.trade_comments.where(user_id: @trade.the_other_user(auth_user)).last
        if @last_comment
          @last_comment.update_attributes(status: ::Trading::TradeComment::Status::REPLIED)

          if last_n && (last_n.is_a?(::Users::Notifications::TradePassive) || last_n.starred ) # If important message to stay, cannot overwrite
            logger.info "|- #{last_n.class.to_s} (#{last_n.id}) is important message: starred? #{last_n.starred}"

          else
            ::Users::Notifications::TradeReply.create(@trade, auth_user)
          end
        end

      else
        flash[:error] = t("trading.ask_question.warning")
      end

      respond_to do |format|
        format.json {
          if @trade_comment
            render json: {user: auth_user, body: params[:comment]}
          else
            render json: make_json_status_hash(false).merge(trade: @trade.as_json({}, auth_user.id))
          end
        }
        format.html { redirect_to(trade_path(@trade)) && return }
      end
    end

    ##
    # Set current user's side of acceptance.  If end up with both sides have set agreement,
    # the OfferBundle will be finalized.
    def accept

      @trade.agree_to_offer!(auth_user, :comment => params[:comment])
      if @trade.completed?
        flash[:notice] = t("trading.trade_completed.notice")
        #trade is completed.  Set appropriate variables here since the other user needs
      else
        flash[:notice] = t("trading.trade_reply_sent.notice", the_other_user_name: @trade.the_other_user(auth_user).user_name.titleize )
      end

      respond_to do |format|
        format.json { render json:{trade: @trade.as_json({}, auth_user.id),
                                    success: true,
                                    needs_parent_approval: @trade.needs_parent_approval?,
                                    reason: flash[:notice]
                                  }
        }
        format.html { render 'approve_confirmed', layout: 'markup' }
      end

    end

    def decline
      @trade.decline_offer!(auth_user)
      flash[:notice] = t("trading.trade_declined.notice")
      respond_to do |format|
        format.json { render json: {success: true, trade: @trade.as_json({}, auth_user.id)} }
        format.html { render 'approve_confirmed', layout: 'markup' }
      end
    end

    def destroy
      if params[:continue].present?
        @trade.end_offer!(auth_user, params[:continue])
        if params[:comment].present?
          @trade_comment = ::Trading::TradeComment.new(user_id: auth_user.id, comment: params[:comment], price: params[:price])
          @trade.trade_comments << @trade_comment
        end
      else
        @trade.end_offer!(auth_user, false)
        #Trade has been ended, params should include a "reason".
        @trade.reason_for_end!(params[:reason], auth_user.id, params[:comment])
      end

      flash[:notice] = t("trading.trade_ended.notice")
      respond_to do |format|
        format.json { render json: make_json_status_hash(true).merge(trade: @trade.as_json({}, auth_user.id)) }
        format.html { redirect_back(users_dashboard_path) }
      end
    end

    def set_meeting_place
      if @trade.last_meeting_place_set_by == 0
        pick_meeting
      else
        respond_to_meeting
      end
    end

    def pick_meeting
      if @trade.needs_alpha_approval? && !@trade.buyer_parent_approve
        logger.info "  |--> Alpha approval needed, so accept 1st b4 pick_meeting"
        accept
      else
        if params[:comment].blank?
          flash[:error] = t("trading.picked_meeting.warning")
          respond_to do |format|
            format.json { render json: make_json_status_hash(false).merge(trade: @trade.as_json({}, auth_user.id))  }
            format.json { redirect_to(pick_meeting_path(id: @trade.id)) }
          end
        end
        @trade.pick_meeting!(auth_user, params[:comment])
        flash[:notice] = t("trading.picked_meeting_sent.notice", the_other_user_name: @trade.the_other_user(auth_user).user_name.titleize )
        respond_to do |format|
          format.json { render json: make_json_status_hash(true, true).merge(trade: @trade.as_json({}, auth_user.id)) }
          format.html { redirect_back(trade_path(@trade)) }
        end
      end
    end

    def respond_to_meeting
      @trade.respond_to_meeting!(auth_user, params[:meeting_action], params[:comment])
      flash[:notice] = t("trading.picked_meeting_sent.notice", the_other_user_name: @trade.the_other_user(auth_user).user_name.titleize )
      respond_to do |format|
        format.json { render json: {success: true, trade: @trade.as_json({}, auth_user.id)} }
        format.html { redirect_back(trade_path(@trade)) }
      end
    end

    def confirm_packed
      if @trade.completed?
        if @trade.is_buyer_side?(auth_user)
          @trade.packed!(true, auth_user.id)
        else
          @trade.packed!(false, auth_user.id)
        end
      end

      if @trade.seller_packed && @trade.buyer_packed
        ::Users::Notifications::TradeMeetingAgreedSent.create(@trade, Admin.cubbyshop_admin, {recipient_user_id: @trade.buyer_id})
        ::Users::Notifications::TradeMeetingAgreedSent.create(@trade, Admin.cubbyshop_admin, {recipient_user_id: @trade.seller_id})
      end

      respond_to do |format|
        format.json { render json: {success: true, trade: @trade.as_json({}, auth_user.id)} }
        format.html { redirect_back(trade_path(@trade)) }
      end
    end

    def confirm_completion
      @trade.confirm_completion!(auth_user, params[:completion_confirmed] )
      flash[:notice] = t("trading.trade_completion_confirmed.notice")
      respond_to do |format|
        format.json { render json: make_json_status_hash(false).merge(trade: @trade.as_json({}, auth_user.id)) }
        format.html { redirect_back(trade_path(@trade)) }
      end
    end

    ###################

    def show_eligibility
      can_trade, reason = check_user_eligibility
      json = make_json_status_hash(true, can_trade).merge(can_trade: can_trade)
      render json: json
    end

    private


    def redirect_with_success
      flash[:notice] = t("trading.trade_updated.notice")
      redirect_to(items_path) && return

    end

    def make_json_status_hash(success_or_not, is_eligible = nil)
      h = super(success_or_not).merge(is_eligible: is_eligible,  reason: flash[:reason], reason_title: flash[:error] )
    end

    ##
    # Sets flash[:error] and flash[:reason] if not eligible

    #less than 4 items APPROVED.
    #less than 7 items APPROVED -> STILL ALLOWED TO TRADE (ask JP)

    def check_user_eligibility(user = nil)
      user ||= auth_user
      if user.is_a?(Child)
        do_check_eligibility =  (!Rails.env.test? || params[:skip_eligibility_check].nil? )
        if do_check_eligibility
          result_h = check_eligibility_for_trading(user)
          return result_h[:result], result_h[:error]

        else
          return true, nil
        end

      elsif user.is_a?(Parent)
        result_h = check_eligibility_for_trading(user)
        return result_h[:result], result_h[:error]
      end

    end

  end
end
