class ItemsController < ApplicationController

  include ::TradeConstants

  helper :categories

  before_filter :set_item_params, :only => [:edit, :create, :update, :destroy]
  before_filter :find_current_item, :only => [:show, :edit, :review, :update, :destroy, :toggle_favorite_item]
  before_filter :verify_user_for_changes!, :only => [:edit, :review, :update, :destroy]
  before_filter :check_selected_category!, :only => [:new, :create]
  before_filter :verify_user_for_likes!, :only => [:likes]


  # GET /items(/search)
  # GET /items(/search).json
  # Expected params
  #   :query given this parameter will generate URL /items/search/hello+kitty
  #   :q the alternative parameter for keywords search, forcing parameter value to be within parameter list like /items/search?q=hello+kitty

  # API response:
  # ----
  # [
  #   "items": [
  #     ...
  #   ],
  #   "limits": {
  #     "items_minimum": <Int, min items needed to trade>
  #     "items_low_warning": <Int, items threshold to warn on low items>
  #   }
  # ]
  def user_likes
    favorite_items = ::Items::FavoriteItem.where(item_id: params[:id]).order('created_at DESC')
    item = Item.where(id: params[:id]).first
    user_ids = favorite_items.map { |fi| fi.user_id }
    users = User.find(user_ids)
    users.sort_by!{|u| u.score(item.owner, ::Items::FavoriteItem.where(item_id: params[:id], user_id: u.id).first)}
    to_return = users.map{ |user| user.as_json }
    respond_to do |format|
      format.json{ render json: {item: item, users: to_return }}
    end
  end

  def index

    execute_search

    set_after_search_info

    respond_to do |format|
      format.js
      format.html { render template: 'items/index.html.haml' }
      format.json { render json: items_search_json }
    end
  end

  ##
  # Entry page to item search
  def search
    @categories = (auth_user) ? Category.for_user(auth_user) : Category.all

    execute_search

    set_after_search_info

    respond_to do |format|
      format.js
      format.html {}
      format.json { render json: items_search_json }
    end
  end

  ##
  # Adds sort by newest in addition to default index search
  def newest
    params[:sort] = 'ACTIVATED_AT DESC'
    params[:school_id] = auth_user.current_school_id
    index
  end

  ##
  #
  def near_by
    if auth_user && auth_user.primary_user_location
      @page_title = "Near by Items"
      @schools = ::Schools::School.search_with_location(auth_user.primary_user_location)

      logger.info "Near by location (#{@schools.size} found): #{auth_user.primary_user_location}"
      @schools.each{|school| logger.info "  #{school.name}, #{school.city}, #{school.zip}"}
      params[:near_by_school_ids] = @schools.collect(&:id)
    end
    index
  end

  def friends
    @page_title = "Friends"
    @friends = auth_user ? auth_user.followed_users : []
    logger.info "User #{auth_user.user_name} friends (#{@friends.size}): #{@friends.collect(&:id)}"
  end

  def likes
    @page_title = "Liked Items"

    @user ||= auth_user
    @items = Item.active.where(id: ::Items::FavoriteItem.where(user_id: @user.id).order('created_at desc').collect(&:item_id)).paginate(page: params[:page] || 1)

    set_after_search_info

    respond_to do |format|
      format.js
      format.html { render template: 'items/index.html.haml' }
      format.json { render json: items_search_json }

    end

  end

  # GET /items/1
  # GET /items/1.json
  def show
    @page_title = @item.display_title
    logger.info "  Item price: #{@item.price}"
    record_item_view!(@item)
    status_list = [::Item::Status::OPEN]
    sort_order = 'id desc'
    if auth_user && auth_user.parent_of?(@item.user)
      status_list << ::Item::Status::PENDING
      sort_order = 'status desc, id asc'
    end
    @other_items = Item.owned_by(@item.user).where(["id != #{@item.id} AND status IN (?)",  status_list] ).order(sort_order).limit(40) if not @item.manageable_by_user?(auth_user)
    @favorite_item_ids = ::Items::FavoriteItem.where(user_id: auth_user.id, item_id: (@other_items.to_a.collect(&:id) + [@item.id]) ).collect(&:item_id) if auth_user
    @is_in_favorite_items = @favorite_item_ids.to_a.include?(@item.id)
    logger.info "| favs (in? #{@is_in_favorite_items}): #{@favorite_item_ids.inspect}"
    logger.info "| permission to user #{auth_user.try(:user_name)}: #{@item.permission_to_user(auth_user)}"
    respond_to do |format|
      format.html # show.html.erb
      format.json do
        render json: @item.detailed_json({:is_follower_user_id => auth_user.try(:id)}, auth_user.try(:id) ).
                   merge(:permission => @item.permission_to_user(auth_user), :comment_threads => make_buyer_based_item_comments_threads(@item),:other_items => @other_items, :favorite_item_ids => @favorite_item_ids.to_a, :is_in_favorite_items => @is_in_favorite_items )
      end
    end
  end

  # GET /items/new
  # GET /items/new.json
  def new
    @menu_title = 'Post Item' if @category
    @item = Item.new(category_id: @category.try(:id) )

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @item }
    end
  end

  # GET /items/1/edit
  def edit
    @page_title = 'Edit Item: ' + @item.display_title
    @menu_title = 'Edit Item'
    session[:original_uri] = request.referer
  end

  # Simpler form of edit item, intended for parent to submit changes or decline/end item.
  # GET /items/1/review
  def review
    @page_title = 'Review Item: ' + @item.display_title
    @menu_title = 'Review Item'
    set_referer_as_redirect_back
    render 'review', layout: 'markup'
  end


  # POST /items
  # POST /items.json
  def create
    @item = Item.new(params[:item])
    @item.load_item_photos_with_params( params[:item] )

    specified_child = nil
    if auth_user.is_a?(Parent)
      specified_child_id = params[:item].try(:[], :user_id)
      if specified_child_id.to_i > 0 && auth_user.children.find { |child| child.id == specified_child_id }
        specified_child = User.find_by_id(specified_child_id)
      end
      specified_child ||= auth_user.children.last # refer to latest child
      @item.status = ::Item::Status::OPEN
    end
    @item.user = specified_child || auth_user
    last_item = Item.owned_by(@item.user).last
    if last_item && last_item.description.strip == @item.description
      logger.info "------ #{@item.user.display_name} is posting duplicate of last item (#{last_item.id})"
      @item = last_item
    else
      logger.info "------ #{@item.user.display_name} creating item #{@item}"
    end

    respond_to do |format|
      if @item.save
        logger.info "------ #{@item.user.display_name} created item #{@item}"
        logger.info " -------------------- DONE w/ item ----------"
        format.html { redirect_to @item, notice: 'Item was successfully created. ' + flash[:notice].to_s }
        format.json { render json: {item: @item, status: :created, success: true, location: @item } }
      else
        set_flash_messages_from_errors(@item)
        format.html { render action: "new", item: params[:item], category_id: params[:category_id] }
        format.json { render json: { error: @item.errors.first.join(' ') }, status: :unprocessable_entity }
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.json
  def update
    @item = Item.find(params[:id])

    logger.info "Item: #{@item}\nw/ param attr: #{params[:item].inspect}"
    respond_to do |format|
      @item.attributes = params[:item].select{|k,v| ![:item_photos, :item_photos_attributes, :location].include?(k.to_sym) }

      @item.load_item_photos_with_params(params[:item] )

      if @item.save

        @item.set_by_user(auth_user)

        logger.info "  C) after save: attr: #{@item.attributes}"

        if manage_item_photos(@item).present? || @item.changed?
          @item.save
          logger.info "  D) attr: #{@item.attributes}"
        end

        format.html {
          redirect_to inventory_approve_item_path(:user_id => "#{@item.owner.id}")
        }
        format.json { render json:{ item: @item, success: true} }
      else
        set_flash_messages_from_errors(@item)
        format.html { render action: "edit" }
        format.json { render json: { error: @item.errors.first.join(' ') }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    @item.destroy

    respond_to do |format|
      format.html { redirect_to items_path }
      format.json { head :no_content }
    end
  end

  def toggle_favorite_item
    if auth_user && (auth_user.id != @item.user_id && !auth_user.is_a?(Parent) )
      @is_in_favorite_items = ::Items::FavoriteItem.toggle_item_to_favorites(@item.id, auth_user.id)
      puts " .. NOW: is_in_favorite_items? #{@is_in_favorite_items}"
    end
    respond_to do |format|
      format.js
      format.html { redirect_to item_path(@item, status: @is_in_favorite_items) }
      format.json { render json: {is_in_favorite_items: @is_in_favorite_items} }
    end
  end


  private

  def find_current_item
    @item = Item.find_by_id(params[:id])
    unless @item
      flash[:error] = "The requested item cannot be found."
      respond_to do|format|
        format.html { redirect_to(items_path) }
        format.json { render json: {:error => flash[:error] }  }
      end
    end
  end

  def set_item_params
    params[:user_id] = auth_user.id
    if (item_params = params[:item])
      item_params[:price] = item_params[:price].to_s.gsub(/(\s*\$\s*)/, '').to_f if item_params[:price].to_f == 0.0
      item_params[:item_photos_attributes] = item_params.delete(:item_photo_urls) if item_params[:item_photo_urls].present?
      item_params[:gender_group] = params[:for_male].to_s + params[:for_female].to_s
      params[:item] = item_params
    end
  end

  def check_selected_category!



    category_id_param = params[:category_id] || params[:item].try(:[], :category_id)
    if category_id_param.to_i.zero? || (@category = Category.find_by_id(category_id_param) ).nil?

      @categories = Category.for_user(auth_user)

      flash[:error] = t("selling.choose_category.header")
      logger.info "  ** Category error: #{flash[:error]}"
      if params[:action].to_s != 'new'
        redirect_to(new_item_path) && return
      end
    else
      @category ||= Category.find_by_id(category_id_param)
    end
  end


  #############################
  # Search helpers

  def execute_search
    @items_search = Item.build_search(params.merge(school_id: params[:school_id] || auth_user.try(:current_school_id) ), auth_user )
    @items_search.execute
    @items = @items_search.results.find_all(&:open?)
    logger.info "-------------------- #{@items_search.inspect}"
    logger.info "  Page #{params[:page]}: #{@items.size} out of total #{@items_search.total}"

  end

  ##
  # After specified item search is done and set to @items, adds extra related info like favorites to current user

  def set_after_search_info
    @page_title ||= 'Items'
    @page_title = params[:query] if params[:query].present?
    @page_title << ' in ' + @category.name if @category
    @favorite_item_ids = ::Items::FavoriteItem.where(user_id: auth_user.id, item_id: @items.collect(&:id)).collect(&:item_id) if auth_user
    @result = @items.map {|i| i.as_json({}, auth_user.id)}
  end

  # If there is @items_search, use it as :total_count; otherwise, simply use @items.size
  def items_search_json
    { items: @result, favorite_item_ids: @favorite_item_ids.to_a,
      page: (params[:page] || 1), per_page: Item.per_page, total_count: (@items_search ? @items_search.total : @items.size),
      limits: {
          items_min_threshold: ITEMS_MIN_THRESHOLD,
          items_low_warning: ITEMS_LOW_WARNING_THRESHOLD
      }
    }
  end


  # ==========================================
  # Record actions

  # To make changes to item, need to be either the kid himself/herself or the parent.
  def verify_user_for_changes!

    unless @item.editable_by_user?(auth_user)
      status_error = @item.errors[:status].present? ? @item.errors[:status].join(' ') : nil
      flash[:error] = status_error || "You do not have permission to the item."
      redirect_back(items_path) && return

    else
      if ItemPhoto.over_the_limit?(@item)
        flash[:notice] = "The images over the limit will be discarded."
      end
    end

  end

  ##
  # If params[:deleted_item_photos] given, existing photos with match would be removed from item_photos.
  # @return <nil or Array of ItemPhoto> nil when no matching parameter is there or when item stays with no-image so default_thumbnail_url not affected.

  def manage_item_photos(item)
    original_count = item.item_photos.to_a.size
    # Delete photos
    deleted_item_photos = params[:deleted_item_photos].to_a
    deleted_item_photos.each{|p| logger.info "  - item_photo: #{p}" }
    item.item_photos.to_a.delete_if{|item_photo| deleted_item_photos.include?(item_photo.image_url) }
    item.save if deleted_item_photos.present?
  end

  ########################

  RECENT_ITEMS_VIEWED_COOKIE = 'recent_items_viewed'
  RECENT_ITEMS_VIEWED_LIMIT = 50

  def record_item_view!(item)
    cookie = cookies[RECENT_ITEMS_VIEWED_COOKIE].to_s
    existing_set = cookie.split(',').collect { |item_id_s| item_id_s.to_i }.uniq
    unless existing_set.include?(item.id)
      0.upto(existing_set.size - RECENT_ITEMS_VIEWED_LIMIT) do |i|
        existing_set.delete_at(0)
      end if existing_set.size >= RECENT_ITEMS_VIEWED_LIMIT
      existing_set << item.id
      cookies[RECENT_ITEMS_VIEWED_COOKIE] = existing_set.join(',')
      item.view_count = item.view_count.to_i + 1
      item.save
      puts "--> Added item #{item.id} to recent_items_viewed cookie"
    end
  end

  ##
  # @return <Array of users>
  def collect_users_info(items)
    user_ids = items.collect(&:user_id).uniq
    User.where(id: user_ids)
  end

  ##
  # Builds a JSON hash of info for this
  # @return <Array of <Hash of buyer, list of comments> > like
  #   { from_user => <User>, comments => <Array of ItemComment between the item owner and buyer> }
  def make_buyer_based_item_comments_threads(item)
    buyer_list = []
    #hash = ::ActiveSupport::OrderedHash.new
    list = item.item_comments.still_open.includes(:buyer, :sender).order('created_at ASC').to_a.group_by(&:buyer)
    list.each_pair do|buyer, comments|
      buyer_list << {from_user: buyer, comments: comments.collect(&:as_json) }
    end
    buyer_list
  end

  def verify_user_for_likes!
    verify_parent_or_child!( params[:id] || params[:user_id] )
  end
end
