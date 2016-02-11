module CategoriesHelper

  BG_COLORS = {
    'no-color' => '',
    'dark-red'=>[204,0,0], 'light-red'=>[255,31,71], 'dark-blue'=>[19,128,218], 'light-blue'=>[64,159,236],
    'dark-green'=>[102,153,0], 'light-green'=>[153,204,0], 'dark-yellow'=>[255,153,0], 'light-yellow'=>[248,200,5],
    'dark-pink'=>[255,62,166], 'light-pink'=>[252,188,205], 'light-violet'=>[170,102,204], 'lego-tile'=>[250,7,1]
  }

  BG_COLOR_CLASSES = %w|dark-red-bg light-red-bg dark-blue-bg light-blue-bg dark-green-bg light-green-bg dark-yellow-bg light-pink-bg dark-pink-bg light-violet-bg lego-tile-bg|

  ##
  # +view_component_id+ The ID of the view object that should have background changed to chosen color.
  # +input_field_id+ The ID of the input field where the chosen color value can be stored.
  def make_bg_color_dropdown_menu_for(input_field_id, view_component_id)
    content_tag(:ul, { role: 'menu', class: 'dropdown-menu', fieldid: input_field_id, viewid: view_component_id } ) do
      BG_COLORS.keys.collect do|bgcolor|
        color_hex = BG_COLORS[bgcolor].is_a?(String) ? BG_COLORS[bgcolor] : '#' + BG_COLORS[bgcolor].collect{|color_i| color_i.to_full_hex }.join
        content_tag(:li, style: "background-color: #{color_hex}") do
          link_to(bgcolor.gsub(/\-bg/i, '').humanize, 'javascript:void(0)', bgcolor: color_hex )
        end
      end.join("\n").html_safe
    end.html_safe
  end

  ADD_PICTURE_IMAGE = '/assets/icons/add@2x.png'

  ##
  # +category+ <Category>
  # +which_picture+ <String> the Category picture name attribute
  # +image_alt+ <String> The tip for the image tag
  def make_category_picture_place_holder(category, which_picture, image_alt = 'Category Icon')
=begin

              = image_tag(category.male_icon_url.present? ? category.male_icon_url : add_image, id:"male_icon_img", alt: "Category Icon for Boys")
              = f.file_field(:male_icon)
=end
    picture_path = category.send( "#{which_picture}_url".to_sym ) # .attributes won't work because these some_icon_url are only generated methods
    image_tag(picture_path.present? ? picture_path : ADD_PICTURE_IMAGE, id:"#{which_picture}_img", class:'vertical-center', alt: image_alt).html_safe
  end

  ##
  # First check current_user's gender.  But if current_user, checks whether category is for female ONLY.
  # @return <Boolean> whether gender should be female
  def is_female_for_category?(category, current_user = nil)
    is_female = false
    if current_user
      is_female = current_user.female?
    else
      is_female = !category.for_male? && category.for_female?
    end
    is_female
  end

  def category_bg_color_for(category, current_user = nil)
    is_female = is_female_for_category?(category, current_user)
    bg_color = is_female ? category.female_icon_background_color : category.male_icon_background_color
    bg_color = '#cccccc' if bg_color.blank?
    bg_color
  end

  ##
  # return <String> may be nil or blank
  def category_icon_url_for(category, current_user = nil)
    is_female = is_female_for_category?(category, current_user)
    icon_url = is_female ? category.female_icon_url : category.male_icon_url
    icon_url = '' if icon_url.to_s == '/assets/'
    icon_url
  end

  def hide_name_for(category, current_user = nil)
    is_female = is_female_for_category?(category, current_user)
    is_female ? category.female_hides_name : category.male_hides_name
  end

  ##
  # ==== Arguments
  #   category <Category>
  #   current_user <User> optional; for determining gender-specific attributes like background color or icon.
  #   options <Hash>
  #     :class - additional CSS class for the outside wrapper of the cell
  #     :url - instead of items_search_category_path
  def make_category_cell(category, current_user = nil, options = {} )
    tag_name = options.delete(:tag_name) || :div
    options[:class] ||= 'category-cell'
    bg_color = category_bg_color_for(category, current_user)
    icon_url = category_icon_url_for(category, current_user)
    hide_name = hide_name_for(category, current_user)

    #options[:style] = "background: url('#{icon_url}') center center no-repeat #{bg_color};"
    options[:style] = "background-color: #{bg_color};"
    url = options[:url] || items_search_category_path(category_id: category.id)
    is_remote = options.delete(:remote) || false

    content_tag(tag_name, options) do
      content_tag(:div, class: (hide_name ? 'category-cell-full-icon vertical-center' : 'category-cell-icon' ) ) do
        icon_tag = ''
        if icon_url.present?
          icon_tag = link_to(url, remote: is_remote){ image_tag(icon_url, alt:'') }
        end
        icon_tag
      end +
      content_tag(:div, class: (hide_name ? '' : "category-cell-label#{category.name.length > 9 ? ' category-cell-label-small' : ''}") ) do
        hide_name ? '' : link_to(category.name, url )
      end
    end
  end
  
  # Part of the category-based posting.
  def sample_category_photo(category)
    gender_suffix = ''
    if category.for_male? && !category.for_female?
      gender_suffix = '_male'
    elsif !category.for_male? && category.for_female?
      gender_suffix = '_female'
    end
    url = category.camera_background_for(current_user)
    url.blank? ? "/assets/items/item_photos/category_photo_#{category.id}#{gender_suffix}.png" : url 
  end

end
