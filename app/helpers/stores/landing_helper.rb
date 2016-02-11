##
# Helper to handle data and view generation of store-related pages,
# such as business card landing page /{user_name}.
module Stores
  module LandingHelper

    CURATED_AVATARS_BY_GENDER = {
        'male'=> [
            'avatar-male-115-driver@2x.png', 'avatar-male-130-ninja@2x.png', 'avatar-male-170-soldier@2x.png',
            'avatar-male-160-soccer@2x.png', 'avatar-male-165-football@2x.png', 'avatar-male-170-hockey@2x.png',
            'avatar-male-255-blue@2x.png', 'avatar-male-715-monkey@2x.png', 'avatar-male-747-shark@2x.png',
            'avatar-male-760-trex@2x.png', 'avatar-male-820-rockhand@2x.png', 'avatar-male-910-controller@2x.png',
            'avatar-male-510-angles@2x.png', 'avatar-male-520-mip@2x.png', 'avatar-male-625-grumpy@2x.png',
            'avatar-male-450-skateboard@2x.png', 'avatar-male-480-spikey@2x.png', 'avatar-male-385-greenfang@2x.png',
            'avatar-male-365-horns@2x.png', 'avatar-male-310-bluestar@2x.png', 'avatar-male-335-purple@2x.png',
            'avatar-male-250-blue@2x.png', 'avatar-male-265-black@2x.png', 'avatar-male-420-drums@2x.png'
        ],
        'female' => [
            'avatar-female-122-ponytail@2x.png',
            'avatar-female-140-brownbow@2x.png',
            'avatar-female-227-orange@2x.png',
            'avatar-female-345-hearts@2x.png',
            'avatar-female-275-aviators@2x.png',
            'avatar-female-310-bucktooth@2x.png',
            'avatar-female-325-happy@2x.png',
            'avatar-female-220-blond@2x.png',
            'avatar-female-425-penguin@2x.png',
            'avatar-female-450-tiger@2x.png',
            'avatar-female-465-owl@2x.png',
            'avatar-female-520-tennis@2x.png',
            'avatar-female-530-soccer@2x.png',
            'avatar-female-110-purple@2x.png',
            'avatar-female-625-furry@2x.png',
            'avatar-female-675-starfish@2x.png',
            'avatar-female-690-whale@2x.png',
            'avatar-female-725-lipstick@2x.png',
            'avatar-female-755-wings@2x.png',
            'avatar-female-760-pants@2x.png',
            'avatar-female-855-watermellon@2x.png',
            'avatar-female-910-cookiehead@2x.png',
            'avatar-female-915-dome@2x.png'
        ]
      }

    CURATED_ITEM_IMAGES_FOR_OLDER_BOYS = [
        "at_at.png", "bb8.png", "injustice.png", "lebron_shoes.png",
        "lebron_shoes_cheaper.png", "lego_technic_car.png", "lego_technic_motorcycle.png", "madden_16.png",
        "minion_with_bear.png", "miposaur.png", "nerf_megacyclone.png", "nhl_playstation.png", "rayman_xbox.png",
        "razor_scooter.png", "skylander_dark_spitfire.png", "skylander_gill_grunt.png", "super_smash_bros.png", "yoda.png"
    ]
    CURATED_ITEM_IMAGES_FOR_YOUNGER_BOYS = [
        "at_at.png", "bb8.png", "disney_infinity.png", "furbacca.png", "injustice.png", "iron_man.png", "madden_16.png",
        "milenium_falcon.png", "minecraft_diamond_steve.png", "minion_with_bear.png", "minions_swim_goggles.png",
        "miposaur.png", "nerf_megacyclone.png", "nhl_playstation.png", "pokemon_figure.png", "rayman_xbox.png",
        "razor_scooter.png", "skylander_dark_spitfire.png", "skylander_gill_grunt.png", "super_smash_bros.png", "t_rex.png",
        "transformer_fallen.png", "transformers_grimlock.png", "yoda.png"
    ]

    CURATED_ITEM_IMAGES_FOR_OLDER_GIRLS = [
        "am_girl_doll_copy.png", "beanie_boo_copy.png", "bracelet_copy.png", "disney_infinity_black_widow.png",
        "ever_after_doll_copy.png", "hello_kitty_pounch.png", "just_dance.png", "nail_polish.png", "nerf_rebelle.png",
        "one_direction_t.png", "phone_case.psd", "purse.png", "racquet.png", "super_smash_bros.png", "voodoo_doll.png", "zoomer_puppy.png"
    ]
    CURATED_ITEM_IMAGES_FOR_YOUNGER_GIRLS = [
        "am_girl_doll.png", "beanie_boo.png", "bracelet.png", "doll_bed.png", "ever_after_doll.png", "frozen_coin_purse.png",
        "furbacca.png", "furreal_dog.png", "just_dance.png", "lego_elf.png", "lego_friends_house.png", "littlest_pet_shop.png",
        "my_little_pony.png", "nerf_rebelle.png", "shopkin_cupcake.png", "shopkins_truck.png", "voodoo_doll.png", "zoomer_puppy.png"
    ]

    AGE_BETWEEN_OLDER_AND_YOUNGDER = 8

    ##
    # items <Array of Item>
    # viewer <User>



    def mix_items_with_curated_items(items, seller, total_item_count = 10)
      age_range = ::Schools::SchoolGroup.grade_to_age_range(seller.grade)
      avatar_list = CURATED_AVATARS_BY_GENDER[seller.gender.downcase].shuffle
      curated_list = CURATED_ITEM_IMAGES_FOR_YOUNGER_BOYS
      curated_folder = 'toys_younger_boys'
      if seller.female?
        if age_range.first > AGE_BETWEEN_OLDER_AND_YOUNGDER
          curated_list = CURATED_ITEM_IMAGES_FOR_OLDER_GIRLS
          curated_folder = 'toys_older_girls'
        else
          curated_list = CURATED_ITEM_IMAGES_FOR_YOUNGER_GIRLS
          curated_folder = 'toys_younger_girls'
        end
      else
        if age_range.first > AGE_BETWEEN_OLDER_AND_YOUNGDER
          curated_list = CURATED_ITEM_IMAGES_FOR_OLDER_BOYS
          curated_folder = 'toys_older_boys'
        else
          curated_list = CURATED_ITEM_IMAGES_FOR_YOUNGER_BOYS
          curated_folder = 'toys_younger_boys'
        end
      end
      i = 0
      picked_curated = curated_list.shuffle[0..(total_item_count - items.size - 1)].collect do|image_name|
        i += 1
        item = Item.new(title: '', description:'')
        item.default_thumbnail_url = "/assets/landing/#{curated_folder}/#{image_name}"
        item.user = Child.new(user_name: seller.user_name)
        avatar_image = avatar_list.delete_at(0)
        if avatar_image == seller.profile_image_name
          avatar_image = avatar_list.delete_at(0)
        end
        item.user.id = i
        item.user.profile_image_name = avatar_image
        item.id = i
        logger.info "| #{i} #{avatar_image} out of #{avatar_list.size} - #{image_name}"
        item
      end

      picked_curated.insert(2, items.first)
      picked_curated.insert(6, items[1] )
      picked_curated
    end
  end
end