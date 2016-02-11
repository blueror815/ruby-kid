##
# Browses through the list of stores and their items (/stores) or specifically showcases one
# store (/stores/:id).  The :id parameter would be the seller's user ID.

class StoresController < ApplicationController

  include ::Users::UsersHelper
  include ::Trading::ControllerHelper
  include ::Stores::LandingHelper
  helper :home

  skip_before_filter :load_account_data, only: [:landing, :show, :search]
  skip_before_filter :verify_auth_user, only: [:landing, :show, :search]
  before_filter :find_current_seller, except: [:index]
  before_filter :find_current_trade, only: [:items_for_trade]

  def index

  end

  ##
  # Special version of the user's store with mix of selected nice items from others as demo.
  def landing
    owner_items = Item.owned_by(@user).open_items.order('price desc').limit(2).to_a
    @items = mix_items_with_curated_items(owner_items, @user)

    logger.info "| Owner #{@user.user_name} has #{owner_items.size} items"

    render layout: 'landing_25'
  end

  ##
  #
  def show
    @page_title = "#{@user.display_name}'s Shop"

    @items = Item.open_items.owned_by(@user).to_a
    if auth_user
      ActiveSupport::Notifications.instrument('process.stores.sort_items', :name => @user.user_name) do
        @favorite_counts = ::Items::FavoriteItem.make_favorite_counts_map(@items.collect(&:id), auth_user.try(:id) )
        puts "-----favorite_counts on showscontroller.rb----W/#{@favorite_counts}"
        @items.sort! do|x, y|
          y.owner_sort_priority({:favorite_counts => @favorite_counts}, auth_user.id) <=> x.owner_sort_priority({:favorite_counts => @favorite_counts}, auth_user.id)
        end
      end
    end
    @result = @items.map {|i| i.as_json({}, auth_user.id)}
    respond_to do|format|
      format.json {
        json_hash = (params[:include_favorite_counts] || request.path =~ /\/users\/\d+\/items/i )  ?
            {items: @result, favorite_counts: @favorite_counts} :
            @result
        render json: json_hash
      }
      format.html
    end

  end

  ##
  # Intentionally made in relation with a trade, re-grouping and sorting items that best suits the types or categories
  # of wanted items.
  # Current conditions:
  #   Items with prices within the same range of the total price of the other's wanted items: price desc, like status, newest
  #   Items outside of the range of the total price of the other's wanted items: price asc, like status, newest
  # /stores/:id/item_for_trades/:trade_id

  def items_for_trade
    @page_title = "#{@user.display_name}'s Items for Trade"

    all_items = Item.open_items.owned_by(@user).to_a

    @items, @more_items = Items::ItemSearch.sort_by_price_cutoff(all_items, @trade.wanted_items_of(@user).sum(&:price) )
    @result = @items.map {|i| i.as_json({}, auth_user.id)}
    @more_results = @more_items.map{|i| i.as_json({}, auth_user.id)}
    respond_to do|format|
      format.json { render json: {items: @result, more_items: @more_results} }
      format.html { render template: 'stores/show' }
    end
  end

  ##
  #
  def search

    @items_search = Sunspot.new_search(Item) do
      paginate :page => params[:page] || 1, :per_page => 20
    end

    params[:query] = params[:q] if params[:query].blank? && params[:q]
    if params[:query].present?
      params[:query] = CGI.unescape(params[:query])
      @items_search.build do
        fulltext params[:query].strip do
          boost_fields :title => 2.0, :keywords => 1.5
        end
      end
    end

    if params[:category_id].present? && (@category = Category.find_by_id(params[:category_id].to_i))
      @items_search.build do
        with :category_ids, params[:category_id].to_i
      end
    end

    @page_title = "#{@user.name} Postings"
    @page_title = params[:query] if params[:query].present?
    @page_title << ' in ' + @category.name if @category

    sort = params[:sort]
    @items_search.build do
      order_by sort.split(/\s+/)[0].downcase.to_sym, sort.split(/\s+/)[1].downcase.to_sym
    end if sort.present? && ItemsHelper.valid_sort?(sort)

    @items_search.execute

    respond_to do |format|
      format.html { render 'index' }
      format.json { render json: @items_search.results }
    end
  end

  ##
  # Specific list of seller's active items with the items already in cart put at top of the order.  In terms of paging,
  # if the carted items aren't enough for the first page, other items are appended to fill up.
  def show_for_cart
    @items = []
    cart_items = @cart[@user.id].to_a
    cart_item_ids = cart_items.collect(&:item_id)
    if params[:cart_items_priority].present? && cart_items.present?
      @items = cart_items.collect(&:item)
    end
    puts "  1st got #{@items.size} cart items"
    expected_index = (params[:page] || 1) * 20
    if @items.size < expected_index
      if cart_items.size > 0
        @items += Item.active.owned_by(@user).where(["id NOT IN (?)", cart_items.collect(&:item_id) ] ).paginate(per_page: 20, page: (params[:page] || 1) )
      else
        @items += Item.active.owned_by(@user).paginate(per_page: 20, page: (params[:page] || 1) )
      end
    end
    puts "  .. then filled up to #{@items.size} items"

    respond_to do|format|
      format.json { render json: {user: @user.as_json,
                                  items: @items.collect{|item| item.as_json.merge(:is_in_cart => cart_item_ids.include?(item.id)) },
                                  cart_item_ids: cart_item_ids }  }
    end
  end

  def follow
    if auth_user.nil? || auth_user.is_a?(Parent) || @user.id == auth_user.id
      @is_following = false
    elsif @user.has_follower?(auth_user)
      ::Stores::Following.delete_all(["user_id = ? and follower_user_id = ?", @user.id, auth_user.id] )
      ::Stores::Following.remove_following_notifications!( auth_user.id, @user.id )
      logger.info "--> Remove #{auth_user.user_name} from following #{@user.user_name}"
      @is_following = false
    else
      following_count = ::Stores::Following.where(user_id: @user.id, follower_user_id: auth_user.id).count
      if following_count > 0
        logger.info "--> Already following"
      else
        ::Stores::Following.create(user_id: @user.id, follower_user_id: auth_user.id )
        logger.info "--> Added #{auth_user.user_name} to follow #{@user.user_name}"
      end
      @is_following = true
    end
    logger.info " .. now following? #{@is_following}"
    respond_to do|format|
      format.json { render json: {:is_following => (@is_following ? 1 : 0), :followed_user_ids => ::Stores::Following.where(follower_user_id: auth_user.id).collect(&:user_id) } }
      format.js
      format.html { redirect_back(store_path(:id => params[:id] ) ) }
    end
  end

  def is_following
    is_following = @user.has_follower?(auth_user)
    respond_to do|format|
      format.json { render json: {:is_following => (is_following ? 1 : 0),  :followed_user_ids => ::Stores::Following.where(follower_user_id: auth_user.id).collect(&:user_id) } }
    end
  end

  private

  def find_current_seller
    id = params[:id] || params[:user_name]
    @user = (id.is_a?(Fixnum) || id.to_s =~ /^[\d]+$/ ) ? User.find_by_id(id) : User.find_by_user_name(id)
    if @user.nil?
      flash[:error] = "Cannot find this seller."
      redirect_back(items_path) && return
    end
  end

  def find_current_trade
    super(:trade_id)
  end

end
