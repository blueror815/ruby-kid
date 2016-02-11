module Trading
  class BuyRequestsController < ApplicationController

    before_filter :verify_auth_user
    before_filter :find_current, only: [:show, :accept, :decline, :sold, :not_sold ]

    def show
      respond_to do |format|
        format.html
        format.json { render json: @buy_request }
      end
    end

    def create

      @buy_request = ::Trading::BuyRequest.new(message: params[:message] )
      @buy_request.items = ::Item.where(id: (params[:item_ids] || [params[:item_id]] ) )
      @buy_request.buyer_id = auth_user.id
      @buy_request.seller_id = @buy_request.items.first.user_id if @buy_request.items.present?

      logger.info "| Make BuyRequest of items #{@buy_request.items.collect(&:id)}"
      respond_to do |format|
        if @buy_request.save
          format.html { redirect_back(users_dashboard_path) }
          format.json { render json: { report: @buy_request, success: true } }
        else
          set_flash_messages_from_errors(@buy_request)
          format.html { redirect_back(newest_items_path) }
          format.json { render json: { error: @buy_request.errors.first.join(' ') } }
        end
      end
    end

    def accept
      @buy_request.attributes = params[:buy_request] || {}
      @buy_request.status = ::Trading::BuyRequest::Status::WAITING_FOR_SELL
      respond_according_to_formats && return
    end

    def decline
      @buy_request.status = ::Trading::BuyRequest::Status::DECLINED
      respond_according_to_formats && return
    end

    def sold
      confirm(::Trading::BuyRequest::Status::SOLD)
    end

    def not_sold
      confirm(::Trading::BuyRequest::Status::WAITING_FOR_SELL)
    end

    private

    def find_current
      @buy_request = ::Trading::BuyRequest.find_by_id(params[:id]) if params[:id]
      if @buy_request
        check_permission(@report)
      else
        br_items = ::Trading::BuyRequestItem.where(item_id: (params[:item_ids] || [params[:item_id]] ) )
        @buy_request = br_items.first.try(:buy_request)
      end

      if @buy_request.nil?
        flash[:error] = "The related buy request cannot be found"
        respond_to do|format|
          format.html { redirect_to(notifications_path) }
          format.json { render json: {:error => flash[:error] }  }
        end
      end
    end

    def check_permission(buy_request)
    end

    ##
    # Same common rendering / redirects during the update of BuyRequest
    def respond_according_to_formats
      respond_to do |format|
        if @buy_request.save
          format.html { redirect_back(users_dashboard_path) }
          format.json { render json: { report: @buy_request, success: true } }
        else
          set_flash_messages_from_errors(@buy_request)
          logger.info "** BuyRequest errors: #{flash[:error]}"
          format.html { redirect_back(newest_items_path) }
          format.json { render json: { error: @buy_request.errors.first.join(' ') } }
        end
      end
    end

    def confirm(status)

      @buy_request.status = status

      respond_according_to_formats && return
    end

  end

end
