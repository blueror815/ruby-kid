module Users
  module UsersHelper

    include ::Doorkeeper::Rails::Helpers
  
    AVATAR_ICON_NAMES = %w|avatar-afro-rockon-small avatar-alien-blue-blonde-small avatar-alien-gray-small avatar-alien-green-purple-eyes-small avatar-alien-green-small avatar-alien-orange-green-small avatar-alien-orange-purple-small avatar-alien-red-big-ears-small avatar-alien-striped-purple-small avatar-angel-fish-small avatar-antennea-robot-small avatar-baseball-player-small avatar-bee-bigeye-small avatar-bigeye-blonde-girl-small avatar-bigeye-brown-hair-boy-small avatar-bigeye-brown-long-hair-small avatar-bigeye-curly-blonde-boy-small avatar-bigeye-girl-glasses-small avatar-bigeye-goatee-small avatar-bigeye-mohawk-boy-small avatar-bigeye-purple-girl-small avatar-bigeye-redhair-boy-small avatar-bigeye-spike-hair-boy-small avatar-black-hair-girl-hero-small avatar-blonde-boy-hero-small avatar-blue-eye-bald-rockon-small avatar-blue-eye-black-hair-rockon-small avatar-blue-shark-small avatar-brown-short-hair-boy-small avatar-cat-bigeye-small avatar-chicken-bigeye-small avatar-clown-fish-small avatar-cow-big-eye-small avatar-crab-small avatar-curly-black-hair-boy-hero-small avatar-deer-big-eye-small avatar-dog-bigeye-small avatar-donkey-big-eye-small avatar-dracula-small avatar-dragon-fish-small avatar-elephant-bigeye-small avatar-fox-big-eye-small avatar-frog-big-eye-small avatar-giraffe-bigeye-small avatar-gray-black-hair-boy-hero-small avatar-gray-roller-robot-small avatar-green-lantern-small avatar-green-mustache-rockon-small avatar-green-spike-hair-rockon-small avatar-green-unicycle-robot-small avatar-handsome-pirate-small avatar-hermit-crab-small avatar-hero-orange-small avatar-hippo-big-eye-small avatar-hockey-small avatar-hunter-fish-small avatar-jellyfish-small avatar-killer-whale-small avatar-koala-bigeye-small avatar-lion-bigeye-small avatar-mario-rockon-small avatar-microchip-robot-small avatar-monkey-bigeye-small avatar-mouse-bigeye-small avatar-ninja-small avatar-octopus-small avatar-orange-bicycle-robot-small avatar-orange-helmet-robot-small avatar-orange-rockon-small avatar-owl-bigeye-small avatar-oyster-small avatar-panda-big-eye-small avatar-penguin-big-eye-small avatar-pig-bigeye-small avatar-pink-rockon-small avatar-pirate-small avatar-puffer-fish-small avatar-rabbit-bigeye-small avatar-raccoon-big-eyes-small avatar-race-car-driver-small avatar-ray-small avatar-red-eyes-gray-roboy-small avatar-red-hair-girl-hero-small avatar-red-hair-girl-small avatar-red-hero-small avatar-referee-rockon-small avatar-robot-hero-small avatar-samurai-small avatar-scuba-diver-small avatar-sea-turtle-small avatar-seahorse-small avatar-seal-small avatar-shadow-kids-brown-hair-small avatar-shark-small avatar-sheep-big-eye-small avatar-sheep-bigeye-small avatar-sheriff-small avatar-solider-small avatar-squid-small avatar-starfish-small avatar-teal-robot-small avatar-tiger-bigeye-small avatar-unicycle-orange-robot-small avatar-unicycle-robot-small avatar-walrus-small avatar-yellow-robot-small avatar-zebra-bigeye-small|
    
    MALE_AVATAR_ICON_NAMES = %w|avatar-male-115-driver avatar-male-130-ninja avatar-male-150-basketball avatar-male-155-baseball avatar-male-160-diver avatar-male-160-soccer avatar-male-165-football avatar-male-170-hockey avatar-male-170-soldier avatar-male-175-volleyball avatar-male-180-tennis avatar-male-180-vampire avatar-male-185-billiards avatar-male-190-samarai avatar-male-195-sheriff avatar-male-210-spikes avatar-male-215-bigmoustache avatar-male-220-swoop avatar-male-240-afro avatar-male-245-lightening avatar-male-250-blue avatar-male-255-blue avatar-male-255-red avatar-male-260-redwheel avatar-male-260-ref avatar-male-265-black avatar-male-280-moustache avatar-male-310-bluestar avatar-male-315-greenlightning avatar-male-320-redskull avatar-male-330-pinkstar avatar-male-335-purple avatar-male-340-greenteeth avatar-male-345-redyellow avatar-male-350-toupee avatar-male-355-green avatar-male-360-bigeye avatar-male-365-horns avatar-male-370-roundtooth avatar-male-375-gray avatar-male-380-fangs avatar-male-385-greenfang avatar-male-410-rapper avatar-male-415-boombox avatar-male-420-drums avatar-male-425-guitar avatar-male-450-skateboard avatar-male-455-shoe avatar-male-460-blueboard avatar-male-465-sunglasses avatar-male-470-brown avatar-male-475-curly avatar-male-477-mohawk avatar-male-480-spikey avatar-male-485-ginger avatar-male-487-messy avatar-male-490-puffy avatar-male-495-blond avatar-male-510-angles avatar-male-515-helmut avatar-male-520-mip avatar-male-525-unicycle avatar-male-530-redeyes avatar-male-535-gray avatar-male-540-sprocket avatar-male-545-cyborg avatar-male-610-bigeye avatar-male-615-fangs avatar-male-620-happy avatar-male-625-grumpy avatar-male-710-racoon avatar-male-715-monkey avatar-male-720-penguin avatar-male-725-fox avatar-male-735-puffer avatar-male-740-glow avatar-male-745-turtle avatar-male-747-shark avatar-male-750-tricerytops avatar-male-755-greentrex avatar-male-760-trex avatar-male-765-steg avatar-male-770-grayviper avatar-male-775-bluedragon avatar-male-780-snake avatar-male-785-reddragon avatar-male-810-mohawk avatar-male-815-ape avatar-male-820-rockhand avatar-male-825-motorcycle avatar-male-910-controller avatar-male-915-headphones avatar-male-920-steve avatar-male-925-sword avatar-male-aaa-blueteeth avatar-male-first-mate|
    
    FEMALE_AVATAR_ICON_NAMES = %w|avatar-female-110-piano avatar-female-110-purple avatar-female-120-blond avatar-female-120-mic avatar-female-122-ponytail avatar-female-125-bigred avatar-female-127-afro avatar-female-129-shortred avatar-female-130-glasses avatar-female-130-guitar avatar-female-140-boombox avatar-female-140-brownbow avatar-female-220-blond avatar-female-225-afam avatar-female-227-orange avatar-female-229-blackhair avatar-female-230-pink avatar-female-235-orangehood avatar-female-240-ref avatar-female-250-red avatar-female-270-designer avatar-female-275-aviators avatar-female-280-hearts avatar-female-285-raybans avatar-female-310-bucktooth avatar-female-320-lips avatar-female-325-happy avatar-female-330-grumpy avatar-female-335-surprise avatar-female-340-halo avatar-female-345-hearts avatar-female-350-crazyeye avatar-female-370-pink avatar-female-375-blond avatar-female-380-black avatar-female-385-redbun avatar-female-410-panda avatar-female-420-giraffe avatar-female-425-penguin avatar-female-430-cat avatar-female-435-bee avatar-female-440-cow avatar-female-450-tiger avatar-female-455-zebra avatar-female-460-rabbit avatar-female-465-owl avatar-female-470-dog avatar-female-475-frog avatar-female-520-tennis avatar-female-530-soccer avatar-female-540-volleyball avatar-female-605-crazyeye avatar-female-610-orange avatar-female-615-dots avatar-female-620-purple avatar-female-625-furry avatar-female-630-fat avatar-female-635-bigeye avatar-female-640-horns avatar-female-670-clown avatar-female-675-starfish avatar-female-677-oyster avatar-female-680-turtle avatar-female-685-jelly avatar-female-687-seal avatar-female-690-whale avatar-female-695-hermit avatar-female-710-nailpolish avatar-female-720-eyeshadow avatar-female-725-lipstick avatar-female-730-perfume avatar-female-750-hatdress avatar-female-755-wings avatar-female-760-pants avatar-female-765-giggle avatar-female-810-black avatar-female-815-raven avatar-female-820-blond avatar-female-830-brunette avatar-female-850-lemon avatar-female-855-watermellon avatar-female-860-strawberry avatar-female-910-cookiehead avatar-female-915-dome avatar-female-920-cheesecake avatar-female-930-cookie avatar-female-aaa-basketball|

    def auth_user
      user = User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
      user || current_user
    end

    # User registration form path
    def user_form_url(_resource, _current_user = nil)
      if _resource.is_a?(Child) && _current_user.try(:id) != _resource.id
          # "/users/child/#{_resource.new_record? ? 'create' : _resource.id}?tab=children"
        _resource.new_record? ? users_create_child_path : users_update_child_path(_resource)
      else
        registration_path(resource_name)
      end
    end
    
    def gender_options(_resource)
      if _resource.is_a?(Child)
        [ ['', ''], %w(Boy Male), %w(Girl Female)]
      else
        [ ['',''], %w(Male Male), %w(Female Female)]
      end
    end
    
    def relationship_type_options
      [ ['',''], ['Father', ::Users::Relationship::RelationshipType::FATHER], 
        ['Mother', ::Users::Relationship::RelationshipType::MOTHER],
        ['Guardian', ::Users::Relationship::RelationshipType::GUARDIAN]
      ]
    end
    
    # Determined by whether which_tab is the currently selected tab
    def profile_tab_css_class(which_tab)
      params[:tab] = 'parent' if params[:tab].blank?
      params[:tab].to_s.downcase == which_tab.downcase ? 'active' : ''
    end
    
    # yield image_name, full_image_url
    # male_or_female <String> MALE, FEMALE or anything else would be general full list AVATAR_ICON_NAMES
    def for_each_avatar_image(male_or_female)
      list = AVATAR_ICON_NAMES
      case male_or_female.to_s.upcase
        when 'MALE'
          list = MALE_AVATAR_ICON_NAMES
        when 'FEMALE'
          list = FEMALE_AVATAR_ICON_NAMES
      end
      list.each{|n| yield( ::User.to_full_profile_image_name(n), ::User.to_profile_image_url(n) ) }
    end
    
    ##
    # If user has profile_image_name only, assemble the full path for avatar.
    # If user's profile_image_url is not present, just show default.  If present, shows the thumbnail version of the image.
    def profile_image_thumbnail(user)
      if user.profile_image_name.present?
        "/assets/avatars/#{user.profile_image_name}" + (user.profile_image_name.ends_with?('.png') ? '' : '.png')
      else
        user.profile_image_url.blank? ? '/assets/avatars/choose-a-picture.png' : user.profile_image_url(:thumb).gsub('@2x', '')
      end
    end

    def grade_options(user)
      options = [ ['', ''] ]
      ::Schools::SchoolGroup::GRADES_HASH.each_pair do|k, v|
        options << [v, k]
      end
      options_for_select( options, user.grade )
    end
    
    def user_name_label(user, tag_name = :span, options = {})
      user_name_css_class = options[:user_name_css_class] || 'text-user-name'
      content_tag(tag_name, class: "#{user_name_css_class} #{user.female? ? 'female' : 'male'}-color") do
        user.is_a?(Parent) ? user.informal_relationship_to(options[:relationship_to_user]) : user.display_name.titleize
      end
    end


    # @return <String HTML>
    def gender_group_icons(gender_group)
      gender_group = 'MF' if gender_group.blank?
      html = ''
      if gender_group =~ /m/i 
        html += content_tag(:span, class:'gender-icon', title: 'For Boys') do
          image_tag("/assets/icons/boy-figure@2x.png", alt: "For Boys")
        end
      end
      if gender_group =~ /f/i
        html += content_tag(:span, class:'gender-icon', title: 'For Girls') do
          image_tag("/assets/icons/girl-figure@2x.png", alt: 'For Girls')
        end
      end
      html.html_safe
    end


    # @return <String> #{count} Item(s)
    def grade_and_item_count_label(user)
      s = ""
      if user.grade
        s << ::Schools::SchoolGroup::GRADES_HASH[user.grade].to_s
      end
      item_count = Item.owned_by(user).active.count 
      if item_count > 0
        s << ' - ' if s.present?
        s << pluralize(item_count, 'Item')
      end
      s
    end

    # @return <String HTML>
    def trade_icon(user, tag_name = :span, html_options = {} )
      icon_name = 'taster'
      if user.trade_count > 0 && user.trade_count < 10
        icon_name = 'single'
      elsif user.trade_count >= 10 && user.trade_count < 50
        icon_name = 'double'
      elsif user.trade_count >= 50 && user.trade_count < 100
        icon_name = 'triple'
      elsif user.trade_count >= 100
        icon_name = 'bsplit'
      end
      title = pluralize(user.trade_count, 'Trade')
      css_class = html_options.delete(:class).to_s + ' trade-count-icon'
      html = content_tag(tag_name, html_options.merge(class: css_class, title: title) ) do
        image_tag("/assets/icons/ice_cream_cones/#{icon_name}@2x.png", alt: title) +
          content_tag(:span) { (user.trade_count > 0) ? user.trade_count.to_s : '' }.html_safe
      end.html_safe
      html
    end

  end
end