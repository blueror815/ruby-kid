module ItemsHelper

  SORT_FIELDS = [['Relevancy', ''], ['Price Low to High', 'PRICE ASC'], ['Price High to Low', 'PRICE DESC'], ['Newest', 'ACTIVATED_AT DESC'], ['Distance', 'LOCATION'] ]
  STEP_PHOTO_TIPS = 'photo_tips'

  def self.valid_sort?(sort)
    SORT_FIELDS.collect { |ar| ar[1] }.include?(sort.to_s.upcase)
  end

  # Scans through current params and collect valid ones.  Actual set of search conditions are based on 
  # ItemsController#make_build.  Can be used to pagination or API call.
  # @return <Hash>
  def current_search_params(search_params = nil)
    search_params ||= params
    h = {}
    h[:query] = search_params[:query].strip if search_params[:query].present?
    h[:category_id] = search_params[:category_id] if search_params[:category_id].to_i > 0
    h[:school_id] = search_params[:school_id] if search_params[:school_id].to_i > 0
    h[:near_by_school_ids] = search_params[:near_by_school_ids] if search_params[:near_by_school_ids].present?
    h[:sort] = search_params[:sort] if ::ItemsHelper.valid_sort?(search_params[:sort] )
    h
  end

  # The switch between Newest and Categories.
  # @options
  #   :css_class - additional CSS style into the container of the tabs
  def section_tabs(options = {})
    css_class = options[:css_class]
    categories_active = (params[:action].to_s == 'user_categories' || @category.is_a?(Category))
    newest_active = (params[:action].to_s == 'newest')
    content_tag(:div, class: "btn-group btn-group-justified #{css_class}", role:'group') do
      content_tag(:div, class: "btn-group", role:'group') do
        link_to(I18n.t('word.newest'),  newest_items_path, class:"btn button-group-link #{button_group_link_css_class(newest_active) }")
      end +
        content_tag(:div, class: "btn-group", role:'group') do
          link_to(I18n.t('word.categories'),  user_categories_path, class:"btn button-group-link #{button_group_link_css_class(categories_active) }")
        end
    end
  end

  def button_group_link_css_class(is_active)
    is_active ? 'light-blue-bg' : 'btn-default light-blue-color'
  end

  def categories_select_options
    cats = auth_user ? Category.for_user(auth_user) : Category.top_categories
    [['-- Please select a category --', nil] ] + cats.collect { |c| [c.name, c.id] }
  end

  def sort_select_options(selected = nil)
    options_for_select(SORT_FIELDS, selected)
  end

  def price_display(price)
    price.nil? ? 'Not Set' : '$' + sprintf("%.2f", price)
  end

  # Selects the default-set thumbnail if item has photos.  Otherwise, returns no image
  def default_thumbnail(item)
    if item.default_thumbnail_url.present?
      item.default_thumbnail_url
    else
      ItemPhoto.default_thumbnail_url_for(item) || '/assets/no_image_thumbnail.jpg'
    end
  end

  def show_photo_tips?
    params[:step].to_s.downcase == STEP_PHOTO_TIPS || @item.item_photos.blank?
  end
  
  def has_item_comments?(item)
    item && item.item_comments.count > 0  
  end
  
  # Checks both item_comments and offer_responses
  # @item_or_offer_bundle <Item or Offers::OfferBundle>
  
  def has_questions_and_offers?(item_or_offer_bundle)
    if item_or_offer_bundle.is_a?(Item)
      has_item_comments?(item_or_offer_bundle)
    else
      (item_or_offer_bundle && item_or_offer_bundle.offer_responses.count > 0)
    end
  end

  ## Creates a button-like link of 
  # * item <Item>
  # * options (optional):
  #     action: whether 'activate' or 'deactivate'
  #     link_text: text following the icon
  #     use_icon: default true
  #     class: CSS class to use
  #     more_class: additional CSS class to default ones
  def item_activation_link(item, options = {})
    attributes = options.clone
    action = attributes.delete(:action) || (item.ended? || item.pending? ? 'activate' : 'deactivate')
    # raise ArgumentError.new("Invalid item activation action") if !%w|activate deactivate|.include?(action)

    path, css_class = '/', attributes.delete(:class)
    more_class = attributes.delete(:more_class)
    link_text = attributes.delete(:link_text)
    use_icon = attributes.delete(:use_icon)
    if item.active?
      path = inventory_deactivate_item_path(id:item.id, tab: params[:tab])
      css_class = "btn btn-warning #{more_class}" if css_class.blank?
    else
      path = inventory_activate_item_path(id:item.id, tab: params[:tab])
      css_class = "btn btn-success #{more_class}" if css_class.blank?
    end
    attributes.merge! id: "item_activation_link_#{item.id}", method: 'put', role: 'button', title: action.titleize, class: css_class
    link_to(path, attributes) do
      use_icon.nil? || use_icon == true ? item_activation_icon(action, link_text) : link_text.to_s
    end
  end
  
  ##
  # * action: whether 'activate' or 'deactivate'
  def item_activation_icon(action, link_text = '')
    content_tag('span', class: 'glyphicon glyphicon-' + (action == 'activate' ? 'ok-circle' : 'remove-circle')) do
      link_text
    end
  end
  
  # Strips away HTML tags, compresses spaces, and truncates with limit given.
  def stripped_compact_text(html, limit = nil)
    s = strip_tags(html).gsub(/(\s{1,})/, ' ')
    limit.to_i > 0 ? s.truncate(limit) : s
  end

  # @options
  #   :more_class <String> in addition to the button's CSS classes, use this to add extra CSS properties like alignment

  def follow_button(seller, follower, options = {})
    return '' if follower.nil? || seller.id == follower.id
    is_follower = options.delete(:is_follower) || seller.has_follower?(follower)
    link_to((is_follower ? 'Following' : 'Follow'), { controller: 'stores', action: 'follow', id: seller.id },
            remote: true, method: 'put', class: "btn-light #{options[:more_class]}", id: "follow_user_#{seller.id}" )
  end

  ##
  # Either Follow button or Trade Icon
  
  def follow_button_or_trade_icon(seller, follower, options = {})
    return '' if follower.nil? || seller.id == follower.id
    is_follower = seller.has_follower?(follower)
    follow_url = { controller: 'stores', action: 'follow', id: seller.id }
    link_options = { remote: true, method: 'put', id: "follow_user_#{seller.id}" }
    if is_follower
      link_to(follow_url, link_options ) { trade_icon(seller, :div, options) }
    else
      follow_button(seller, follower, options.merge(is_follower: is_follower) )
    end
  end



  ##
  # Heart icon to toggle the Like status of the item in the buyer's favorite items list.
  # @already_favorite <boolean> optional. If nil, the method would query the database.
  # @options
  #   :link_css_class <String> default is "favorite-heart"
  def favorite_item_icon(item, buyer, already_favorite = nil, options = {})
    return '' if buyer.nil? || item.user_id == buyer.id || buyer.is_a?(Parent)
    already_favorite = ::Items::FavoriteItem.where(item_id: item.id, user_id: buyer.id).count > 0 if already_favorite.nil?
    status_name = already_favorite ? 'filled' : 'open'
    link_to( toggle_favorite_item_path(id: item.id),
              id: "favorite_item_icon_#{item.id}", remote: true, method:'put', 
              class: options[:link_css_class] || "favorite-heart", 'data-toggle'=>'tooltip', :title =>"Set as your favorite item") do
      image_tag("/assets/icons/heart-#{status_name}@2x.png", class: "heart-#{status_name}")
    end
  end

  ##
  # Heart icon for displaying number of users who like the item.
  def favorite_count_icon(item, like_count = 0)
    return nil if like_count.to_i == 0
    status_name = (like_count && like_count > 0) ? 'filled' : 'open'
    button_tag( (like_count && like_count > 0 ? like_count.to_s : ''),
              id: "favorite_item_icon_#{item.id}", style: "background-color:transparent;",
              class: "favorite-heart heart-#{status_name}", 'data-toggle'=>'tooltip', :title =>pluralize(like_count, 'LIke') ) do
      image_tag("/assets/icons/heart-#{status_name}@2x.png", class: "heart-#{status_name}", alt: like_count ) +
        content_tag(:span, class:'favorite-item-counter') { like_count.to_s }
    end
  end

  ##
  # The age group options relative to the user's current age. Resulting options would be
  def relative_age_group_selector_for(current_user)

  end
  
end