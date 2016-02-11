##
# The mass items management controller instead of the single items controller

class Inventory::ManagerController < ApplicationController

  helper :items, 'users/users'

  include ::Trading::TradesHelper

  before_filter :verify_owner!, :only => [:index, :approve]
  before_filter :find_items, :verify_manager!, :only => [:activate, :deactivate, :decline]


  def index
    params[:tab] = 'active' if params[:tab].blank?
    tab = params[:tab]
    per_page = (request.format == 'application/json') ? 100 : 20

    @user = auth_user
    if tab =~ /all/i
      @items = Item.owned_by(@owner || @user).pending_then_open
    elsif tab =~ /^pending/i
      @items = Item.owned_by(@owner || @user).pending.order('id asc')
    elsif tab =~ /^inactive/i
      @items = Item.owned_by(@owner || @user).inactive
    else
      @items = Item.owned_by(@owner || @user).active
    end
    @items = @items.includes(:user, :item_photos, :categories, :trade_items).paginate(page: params[:page], per_page: per_page)
    @total_count = @items.count
    @items = @items.to_a

    sort_params = {}
    if params[:include_favorite_counts]
      @favorite_counts = ::Items::FavoriteItem.make_favorite_counts_map(@items.collect(&:id))
      sort_params[:favorite_counts] = @favorite_counts
    end
    set_with_trading_info!(@items, @owner, false)
    @items = @items.sort! do|x, y|
      y.owner_sort_priority(sort_params, auth_user.id) <=> x.owner_sort_priority(sort_params, auth_user.id )
    end

    #this just slows down the request
    #@items.each do|item|
    #  active_trade_h = item.active_trade_json
    #  logger.info "| %5d | status %8s | needs_action? %5s | breathing? %5s | %s | %s" %
    #                  [ item.id, item.status, active_trade_h.try(:[], :needs_action), active_trade_h.try(:[], :breathing), active_trade_h.try(:[], :title), active_trade_h.try(:[], :subtitle) ]
    #end

    @page_title ||= 'Inventory Manager - ' + tab.titleize

    respond_to do |format|
      format.json {
        json_hash = params[:include_favorite_counts] ?
          {items: @items, favorite_counts: @favorite_counts} :
          {items: @items, total_count: @total_count}
        render json: json_hash
      }
      format.html { render @owner ? 'approve' : 'index', layout: 'layouts/markup' }
    end
  end

  ##
  # Display of items for approval
  def approve
    params[:tab] = 'pending'
    @page_title = @owner ? "Approve #{@owner.display_name.titleize}'s Items" : 'Approve Items'
    @menu_title = "Review Item"

    index
  end

  ##
  # params:
  #   :id <item ID> one single item
  #   :item_ids <Array of item IDs> items to activate
  #   :decline_item_ids <Array of item IDs> deactivate these items and also remove these from the items to activate.
  def activate
    deactivate_ids = @decline_items.to_a.collect(&:id)
    user_ids = Set.new
    @items.each do |item|
      next if deactivate_ids.include?(item.id)
      item_params = params["item_#{item.id}"]
      item.attributes = item_params if item_params
      logger.info " [ + ] #{item.id} - #{item_params}"
      item.activate! if !@testing
      user_ids << item.user_id
    end
    @decline_items.to_a.each { |item|
      logger.info " [ x ] #{item.id}"
      item.decline! if !@testing
      user_ids << item.user_id
    }
    if auth_user.is_a?(Parent) and auth_user.account_confirmed
      clean_pending_item_notifications!( user_ids )
    end
    update_user_data!( user_ids )

    if !auth_user.account_confirmed
      if ::Users::Notifications::NeedsAccountConfirm.where(recipient_user_id: auth_user.id).empty?
        ::Users::Notifications::NeedsAccountConfirm.create(sender_user_id: Admin.cubbyshop_admin.id, recipient_user_id: auth_user.id)
        if request.headers['X-App-Name'].eql? 'kidstrade-ios'
          ::NotificationMail.create_from_mail(Admin.cubbyshop_admin.id, auth_user.id, UserMailer.account_confirmation_available(auth_user))
        end
        ::Jobs::VerifyAccountReminder.new(auth_user.id).enqueue!
      end
    end

    flash[:notice] = 'Items activated successfully'
    respond_to do |format|
      format.html {
        if !auth_user.account_confirmed
          redirect_to :account_confirmation
        else
          render 'approve_confirmed', layout: 'markup'
        end
      }
      format.js
      format.json { render json: {success: true, item_count: @items.size} }
    end
  end

  def deactivate

    user_ids = Set.new
    @items.to_a.each { |item|
      logger.info " [ - ] #{item.id}"
      item.deactivate! if !@testing
      user_ids << item.user_id
    }
    update_user_data!( user_ids )

    flash[:notice] = 'Items deactivated successfully'
    respond_to do |format|
      format.html { redirect_back(params[:return_url] || inventory_manager_index_path(tab: params[:tab], user_id: params[:user_id])) }
      format.js
      format.json { render json: {success: true, item_count: @items.size} }
    end

  end

  def decline
    user_ids = Set.new
    @items.to_a.each { |item|
      logger.info " [ x ] #{item.id}"
      item.decline! if !@testing
      user_ids << item.user_id
    }
    clean_pending_item_notifications!(user_ids)
    update_user_data!( user_ids )

    flash[:notice] = 'Items declined successfully'
    respond_to do |format|
      format.html { redirect_back(params[:return_url] || inventory_manager_index_path(tab: params[:tab], user_id: params[:user_id])) }
      format.js
      format.json { render json: {success: true, item_count: @items.size} }
    end
  end

  def item_for_approval_notice
    @item = Item.open_items.last
    @sender = @item.user
    @recipient = @sender.parents.first
    @recipient.email = 'briangangster@gmail.com'

    @relationship = @recipient.relationship_type_to(@item.user)
    case @relationship
      when 'FATHER'
        @relationship = 'Dad'
      when 'MOTHER'
        @relationship = 'Mom'
    end

    @main_paragraphs = ["As soon as you approve, the trading can begin!"]
    @sub_paragraphs = [
        "Your child has been busy snapping pictures and setting prices, but until you approve the items, all #{@sender.try(:pronoun_form) || 'the child'} can do is watch while other kids have all the fun.",
        "Since this is their first time posting, please review each item carefully for picture quality, price and spelling."
    ]

    render template: 'user_mailer/item_for_approval', layout: 'notification_mail'
  end

  private

  ##
  # All including children.

  def owner_ids
    if auth_user.is_a?(Child)
      [auth_user.id]
    else
      [auth_user.id] + auth_user.children.select("secondary_user_id").collect(&:secondary_user_id)
    end
  end

  def find_items
    @testing = params[:testing].to_i == 1
    @items = []
    if params[:id].present?
      @items = @items + [Item.find_by_id(params[:id])].compact
    end
    if params[:item_ids].present?
      @items = @items + Item.where(id: params[:item_ids].to_a)
    end
    if params[:decline_item_ids].present?
      @decline_items = Item.where(id: params[:decline_item_ids].to_a)
    end
    logger.info "| items #{@items.to_a.collect(&:id)}"
    #if @items.blank?
    #  flash[:error] = "Could not find items for management."
    #  redirect_back(notifications_path) && return
    #end
  end

  def verify_owner!
    @user = auth_user
    @owner = User.find_by_id(params[:user_id]) if params[:user_id]
    flash[:error] = "Could not find the child" if params[:user_id] && @owner.nil?
    if @owner && (@owner.id != @user.id && @user.children.none? { |child| child.id == @owner.id })
      flash[:error] = "You do not have permission to the items"
      @owner = nil
    end
    if flash[:error].present?
      logger.warn "** verify_owner #{params[:user_id]}: auth_user #{auth_user.id} #{flash[:error] }"
      respond_to do |format|
        format.json { render json: {error: flash[:error]} }
        format.html { redirect_to('/403') }
      end
    end

  end

  # The changes of item allowed only to the parent: activate, deactivate, destroy
  #
  def verify_manager!
    manage_action = [:deactivate, :decline].include?(params[:action].to_sym) ? :deactivate : :activate
    unless @items.all? { |item| item.manageable_by_user?(auth_user, manage_action) }
      status_error = @items.find { |item| item.errors[:status].present? ? item.errors[:status].join(' ') : nil }
      flash[:error] = status_error || "You do not have permission to #{params[:action].to_s.downcase} the item(s)."
    end
    if @decline_items.present? && !@decline_items.all? { |item| item.manageable_by_user?(auth_user, :deactivate) }
      flash[:error] = "You do not have permission to the items."
    end

    if flash[:error].present?
      logger.warn "** verify_manager: auth_user #{auth_user.id} #{flash[:error] }"
      puts "** verify_manager: auth_user #{auth_user.id} #{flash[:error] }"
      respond_to do |format|
        format.json { render json: {error: flash[:error]} }
        format.html { redirect_to('/403') }
      end

    end
  end


  # Override of the one in NotificationHandler.  Find all those pending items notifications.
  def clean_pending_item_notifications!(owner_user_ids)
    owner_user_ids.each do|owner_user_id|
      pending_item_count = ::Item.pending.where(user_id: owner_user_id).count
      logger.info "   | user #{owner_user_id} has #{pending_item_count} pending items"
      if pending_item_count < 1
        ::Users::Notification.where(sender_user_id: owner_user_id, related_model_type: 'Child',
                                    related_model_id: owner_user_id, title: ::Item::PENDING_ITEM_TITLE).
          destroy_all
      end
    end
  end

  ##
  # Updates each user's data like item_count
  def update_user_data!(owner_user_ids)
    owner_user_ids.each do|user_id|
      ::User.recalculate_item_count_of!(user_id)
    end
  end


end
