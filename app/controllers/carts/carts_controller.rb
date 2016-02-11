module Carts
  class CartsController < ApplicationController
    
    helper :items
    
    before_filter :find_item, only: [:add, :update, :delete]
    
    # All items in cart, grouped by sellers
    # GET /carts
    # GET /carts.json
    def index
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @cart }
      end
    end
  
    # Show cart of only that seller 
    # GET /carts/1
    # GET /carts/1.json
    def show
      @seller = User.find_by_id(params[:seller_id] )
      if @seller.nil?
        flash[:error] = 'Cannot find the seller.'
        redirect_to( action: 'index' ) && return
      end
      @cart_items = @cart[ @seller.id ]
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @cart.as_json(seller_id: @seller.id) }
      end
    end
  
    # POST /carts/add/1
    def add
  
      respond_to do |format|
        
        if @cart.add_item(@item, params[:quantity] )
          format.js
          format.html { redirect_to :action => 'index', notice: 'Cart item was successfully created.' }
          format.json { render json: @cart.as_json(seller_id: @item.user_id), success: true, status: :created }
        else
          format.html { render action: 'index' }
          format.json { render json: {errors: @cart.errors.messages,success: false, status: :unprocessable_entity } }
        end
      end
    end
  
    # PUT /carts/1
    # PUT /carts/1.json
    def update
      
      respond_to do |format|
        if @cart.update_item(@item, params[:quantity] )
          format.js
          format.html { redirect_to action: 'index', notice: 'Cart item was successfully updated.' }
          format.json { render json: @cart.as_json(seller_id: @item.user_id) }
        else
          format.js { head :no_content } # Not many attributes for update
          format.html { render action: 'index' }
          format.json { render json: {errors: @cart.errors.messages,success: false, status: :unprocessable_entity } }
        end
      end
    end
  
    # DELETE /carts/1
    # DELETE /carts/1.json
    def delete
      @cart.delete_item(@item)
  
      respond_to do |format|
        format.js
        format.html { redirect_to action: 'index', notice: 'Cart item was successfully removed.' }
        format.json { render json: @cart.as_json(seller_id: @item.user_id) }
      end
    end
    
    private
    
    def find_item
      @item = Item.find_by_id(params[:item_id] )
      if @item.nil?
        flash[:error] = "Cannot find the related item"
      elsif !@item.open?
        flash[:error] = "The item is not available for trade"
      end
      if flash[:error].present?
        redirect_to(:action => :index) && return
      end
    end
  end
end