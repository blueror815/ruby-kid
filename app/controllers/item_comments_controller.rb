class ItemCommentsController < ApplicationController

  before_filter :find_current_item_comment, :only => [:show, :edit, :destroy, :update]
  before_filter :find_current_item, :only => [:new, :create]
  before_filter :verify_current_item_comment!, :only => [:edit, :destroy, :update]

  # GET /item_comments
  # GET /item_comments.json
  def index
    @item_comments = ItemComment.where(recipient_user_id: auth_user.id).paginate(page: params[:page] || 1, per_page: 20)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @item_comments }
    end
  end

  # GET /item_comments/1
  # GET /item_comments/1.json
  def show

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: {item_comment: @item_comment, item: @item_comment.item.more_json, user: @item_comment.the_other_user} }
    end
  end

  # GET /item_comments/new
  # GET /item_comments/new.json
  def new
    @menu_title = t('trading.ask_question.header')

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @item_comment }
    end
  end

  # GET /item_comments/1/edit
  def edit
  end

  # If the author is a seller, not the buyer, either :recipient_user_id or :parent_id would required to determine the
  # buyer recipient.
  # POST /item_comments
  # POST /item_comments.json
  def create
    @item_comment = ItemComment.new(params[:item_comment])
    if @item_comment.parent_id && @item_comment.parent_item_comment
      @item_comment.parent_item_comment ||= ::ItemComment.find_by_id(@item_comment.parent_id)
      @item_comment.buyer_id = @item_comment.parent_item_comment.buyer_id
      @item_comment.item_id ||= @item_comment.parent_item_comment.item_id
      @item_comment.recipient_user_id = @item_comment.parent_item_comment.the_other_user_id(auth_user)
    else
      @item_comment.buyer_id ||= auth_user.id
      @item_comment.recipient_user_id = @item.user_id
    end
    @item_comment.user_id = auth_user.id
    @item_comment.recipient_user_id ||= @item_comment.the_other_user_id(auth_user)
    #logger.warn "> Comment from #{@item_comment.user_id} to #{@item_comment.recipient_user_id}: valid? #{@item_comment.valid?}\n#{@item_comment.attributes.to_yaml}"

    respond_to do |format|
      if @item_comment.save
        format.html { redirect_to @item_comment, notice: 'Item comment was successfully created.' }
        format.json { render json: {item_comment: @item_comment, status: :created, success: true} }
        format.js
      else

        flash[:error] = @item_comment.errors.values.join('.  ')
        format.html { render action: "new" }
        format.json { render json: {error: flash[:error], success: false} }
        format.js
      end
    end
  end

  # PUT /item_comments/1
  # PUT /item_comments/1.json
  def update

    respond_to do |format|
      if @item_comment.update_attributes(params[:item_comment])
        format.html { redirect_to @item_comment, notice: 'Item comment was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @item_comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /item_comments/1
  # DELETE /item_comments/1.json
  def destroy
    @item_comment.destroy

    respond_to do |format|
      format.html { redirect_to item_comments_url }
      format.json { head :no_content }
    end
  end

  private

  # item_id required
  def find_current_item
    set_referer_as_redirect_back
    item_id = @item_comment.try(:item_id) || params[:item_comment].try(:[], :item_id) || params[:item_id]
    @item = (item_id.to_i > 0) ? Item.find_by_id(item_id) : nil
    if @item.nil?
      flash[:error] = "Cannot find the related item"
      redirect_back(newest_items_path) && return
    end
  end

  def find_current_item_comment
    @item_comment = ItemComment.find_by_id(params[:id])
    if @item_comment.nil?
      flash[:error] = "Cannot find the requested comment"
      redirect_to(item_comments_path) && return
    end
  end

  def verify_current_item_comment!
    if ![user_id, recipient_user_id, seller_user_id].include?(auth_user.id) && !auth_user.parent_of?(self.sender) && !auth_user.parent_of?(self.recipient)
      flash[:error] = "You do not have permission to access this comment"
      redirect_to(item_comments_path) && return
    end
  end
end
