##
# Controller module with commonly used methods shared among OfferResponsesController, OfferBundlesController, etc
module Trading
  module ControllerHelper

    def check_permission(trade_comment_or_trade)
      if trade_comment_or_trade && trade_comment_or_trade.editable_by_user?(auth_user) == false
        flash[:error] = "You do not have permission to access this trade."
        respond_to do |format|
          format.json { render json: make_json_status_hash(false) && return }
          format.html { redirect_back(item_path_of_items) && return }
        end
      end
    end

    def parse_quantities_map(_params = nil)
      _params ||= params
      quantities_map = {}
      _params.each_pair do |k, v|
        if k.to_s =~ /^quantity_of_(\d+)/ && v.to_i > 0
          quantities_map[$1.to_i] = v.to_i
        end
      end
      quantities_map
    end


    def find_current_trade(trade_id_param = :id)
      @trade = ::Trading::Trade.find_by_id(params[trade_id_param])
      if @trade.nil?
        cannot_find_trade_response(trade_id_param) && return
      else
        set_extra_trade_attributes(@trade)
        @trade.save if @trade.changed?
      end
      check_permission(@trade)
    end


    # Parameters like real_name may be added
    def set_extra_trade_attributes(trade)
      if (real_name = params[:real_name] || params[:buyer_real_name] || params[:seller_real_name] ).present?
        if trade.is_buyer_side?(auth_user)
          trade.buyer_real_name = real_name
        elsif trade.is_seller_side?(auth_user)
          trade.seller_real_name = real_name
        end
      end
    end

    def cannot_find_trade_response(trade_id_param = :id)
      flash[:error] = (params[trade_id_param]) ? 'Cannot find that trade.' : 'Cannot make a trade.'
      respond_to do |format|
        format.json { render json: make_json_status_hash(false) && return }
        format.html { redirect_back(item_path_of_items) && return }
      end
    end

    def find_current_items
      item_id = params[:item_id] || params[:item_ids] || []
      item_id = [item_id] if item_id.is_a?(Numeric)
      @items = Item.where(["id IN (?)", item_id])
      if @items.blank?
        flash[:error] = 'The related items cannot be found.'
        respond_to do |format|
          format.json { render json: make_json_status_hash(false) && return }
          format.html { redirect_back(item_path_of_items) && return }
        end
      end
    end

    # Common redirect away page with notices
    def item_path_of_items(items = nil)
      items ||= @items
      items.present? ? item_path(@items.last) : items_path
    end

  end
end
