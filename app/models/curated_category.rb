##
# Storing a list of items for specific CategoryGroup's category that's used in Welcome Kids.
# Polymorphic join table between CategoryGroup and Category, in the same way as CategoryGroupMapping,
# but simpler without the customized attributes like icon, background_color.
class CuratedCategory < ActiveRecord::Base
  attr_accessible :order_index, :category_group_id, :category_id

  belongs_to :category_group
  belongs_to :category

  has_many :category_curated_items, :class_name => 'Items::CategoryCuratedItem'

  before_create :set_defaults!

  def self.get_from_age_group(grade = 10, gender = "MALE", count = 6)
    if grade.eql? 100 or grade.eql? 101 or grade < 6
      if gender.eql? "FEMALE"
        #category_group Younger Girls
        id = CategoryGroup.where(name: "Younger Girls").first
      else
        #Younger Boys
        id = CategoryGroup.where(name: "Younger Boys").first
      end
    else
      #older
      if gender.eql? "FEMALE"
        #Older Girls
        id = CategoryGroup.where(name: "Older Girls").first
      else
        #Older Boys
        id = CategoryGroup.where(name: "Older Boys").first
      end
    end
    CuratedCategory.where(category_group_id: id).order(:order_index).limit(count).compact
  end

  def as_json(options = {})
    #get photos, add to end of it
    hash = Category.find(self.category_id).as_json
    photos = self.category_curated_items.includes(:item).map do |cat_cur_item|
      cat_cur_item.item.item_photos.first.as_json
    end
    hash.merge(photos: photos)
  end

  def to_s
    '<CuratedCategory(%s) category_group_id %s, category_id %s, order_index %d>' % [id.to_s, category_group_id.to_s, category_id.to_s, order_index.to_i]
  end

  def self.populate_older_boys_curated_category
    nerf_cat_id = CuratedCategory.get_id_for_cat("Nerf")
    xbox_cat_id = CuratedCategory.get_id_for_cat("Xbox")
    clothes_cat_id = CuratedCategory.get_id_for_cat("Clothes")
    sports_cat_id = CuratedCategory.get_id_for_cat("Sports")
    lego_cat_id = CuratedCategory.get_id_for_cat("LEGOs")
    playstation_cat_id =  CuratedCategory.get_id_for_cat("Playstation")
    
    category_group_id = CategoryGroup.where("name='Older Boys'").first.id

    #now create curated categories
    nerf_cur_cat = CuratedCategory.create(category_id: nerf_cat_id, order_index: 1, category_group_id: category_group_id)
    xbox_cur_cat = CuratedCategory.create(category_id: xbox_cat_id, order_index: 3, category_group_id: category_group_id)
    clothes_cur_cat = CuratedCategory.create(category_id: clothes_cat_id, order_index: 2, category_group_id: category_group_id)
    sports_cur_cat = CuratedCategory.create(category_id: sports_cat_id, order_index: 6, category_group_id: category_group_id)
    lego_cur_cat = CuratedCategory.create(category_id: lego_cat_id, order_index: 5, category_group_id: category_group_id)
    playstation_cur_cat = CuratedCategory.create(category_id: playstation_cat_id, order_index: 4, category_group_id: category_group_id)

    CuratedCategory.create_images(nerf_cat_id, nerf_cur_cat.id, ["http://s17.postimg.org/la2ec89xb/Nerf_Ball.jpg", "http://s21.postimg.org/5q4k9pvcn/Nerf_gun3.jpg", "http://s22.postimg.org/4say0iwu9/Nerf_Bow.jpg", "http://s7.postimg.org/mqp9c606j/nerf_gun2.jpg"])
    CuratedCategory.create_images(xbox_cat_id, xbox_cur_cat.id, ["http://s9.postimg.org/k4sj9vu27/Xbox_Rock_Band.jpg", "http://s28.postimg.org/pdghp0li5/Xbox_Controller.jpg", "http://s7.postimg.org/fv5hcfmnf/Xbox_Lego_Dimensions.jpg", "http://s7.postimg.org/oeova6uzv/Xbox_Minecraft.jpg"])
    CuratedCategory.create_images(clothes_cat_id, clothes_cur_cat.id, ["http://s14.postimg.org/dnnqgay69/older_clothes_burton.jpg", "http://s1.postimg.org/5fnouro1b/older_clothes_curry.jpg", "http://s15.postimg.org/z8qyyx717/older_clothes_lebron.jpg", "http://s11.postimg.org/r2wibcmer/older_clothes_Dez_Bryant.jpg"])
    CuratedCategory.create_images(sports_cat_id, sports_cur_cat.id, ["http://s13.postimg.org/qxxpts3dz/older_sports_crosby.png", "http://s15.postimg.org/kvxj0ln17/older_sports_skateboard.png", "http://s15.postimg.org/wstqytecb/older_sports_snowboard.png", "http://s2.postimg.org/wfwdsocbd/older_sports_sneakers.png"])
    CuratedCategory.create_images(lego_cat_id, lego_cur_cat.id, ["http://s13.postimg.org/m8ur1vvaf/older_lego_chess.png", "http://s3.postimg.org/fs90qjk2b/older_lego_mindstorm.png", "http://s1.postimg.org/b1shhsi9b/older_lego_racecar.png", "http://s1.postimg.org/enyaufomn/older_lego_xwing.png"])
    CuratedCategory.create_images(playstation_cat_id, playstation_cur_cat.id, ["http://s10.postimg.org/3u6m8mgo9/older_PS_controller.jpg", "http://s1.postimg.org/qz0g5zpf3/older_PS_Journey.png", "http://s10.postimg.org/xslz4n209/older_PS_NBA2014.png", "http://s22.postimg.org/zdgxxby69/older_PS_PS3_sytem.png"])
  end

  def self.populate_older_girls_curated_category
    nerf_cat_id = CuratedCategory.force_cat_id_for_cat("Clothes")
    xbox_cat_id = CuratedCategory.force_cat_id_for_cat("Accessories")
    clothes_cat_id = CuratedCategory.get_id_for_cat("Sports")
    sports_cat_id = CuratedCategory.get_id_for_cat("Collectibles")
    lego_cat_id = CuratedCategory.get_id_for_cat("Arts & Crafts")
    playstation_cat_id =  CuratedCategory.get_id_for_cat("Video Games")

    category_group_id = CategoryGroup.where("name='Older Girls'").first.id

    #now create curated categories
    nerf_cur_cat = CuratedCategory.create(category_id: nerf_cat_id, order_index: 1, category_group_id: category_group_id)
    xbox_cur_cat = CuratedCategory.create(category_id: xbox_cat_id, order_index: 2, category_group_id: category_group_id)
    clothes_cur_cat = CuratedCategory.create(category_id: clothes_cat_id, order_index: 3, category_group_id: category_group_id)
    sports_cur_cat = CuratedCategory.create(category_id: sports_cat_id, order_index: 4, category_group_id: category_group_id)
    lego_cur_cat = CuratedCategory.create(category_id: lego_cat_id, order_index: 5, category_group_id: category_group_id)
    playstation_cur_cat = CuratedCategory.create(category_id: playstation_cat_id, order_index: 6, category_group_id: category_group_id)

    CuratedCategory.create_images(nerf_cat_id, nerf_cur_cat.id, ["http://s18.postimg.org/voee17z09/Clothes_Lululemon.jpg", "http://s18.postimg.org/s7cby8zy1/Girl_clothes_skirt.jpg", "http://s24.postimg.org/d99fxkh8l/Girl_Clothes_Taylor_shirt.jpg", "http://s4.postimg.org/es4103jnx/Girl_clothes_Uggs.jpg"])
    CuratedCategory.create_images(xbox_cat_id, xbox_cur_cat.id, ["http://s21.postimg.org/nevuhyq5z/Accessories_Coach_wallet.jpg", "http://s11.postimg.org/y05c87l2b/Accessories_Heart_sunglasses.png", "http://s10.postimg.org/lvi7ycql5/Accessories_nail_polish.jpg", "http://s9.postimg.org/5fsgihvkf/Accessories_Star_bracelets.jpg"])
    CuratedCategory.create_images(clothes_cat_id, clothes_cur_cat.id, ["http://s12.postimg.org/q94bvuy7x/Girl_sports_pink_blue_bag.jpg", "http://s28.postimg.org/fetiaqa0d/Girl_sports_soccer_cleats.jpg", "http://s9.postimg.org/sbmwvludr/Girl_sports_softball_mitt.jpg", "http://s30.postimg.org/y0sn1jhy9/Girl_Sports_tennis_skirt.jpg"])
    CuratedCategory.create_images(sports_cat_id, sports_cur_cat.id, ["http://s2.postimg.org/4pqufwqnt/Collectibles_Beanie_Boo.jpg", "http://s13.postimg.org/oa0onr8l3/Collectibles_Hello_Kitty.jpg", "http://s16.postimg.org/l5zr6taph/Collectibles_Japanese_erasers.jpg", "http://s13.postimg.org/eych0nfpz/Funko_Pop_Leia_Jabba.jpg"])
    CuratedCategory.create_images(lego_cat_id, lego_cur_cat.id, ["http://s14.postimg.org/vnugg145t/Arts_Crafts_bunny.jpg", "http://s17.postimg.org/ffl4345wv/Arts_Crafts_Charm.jpg", "http://s21.postimg.org/54sgg36k7/Arts_Crafts_Friendship_bracelet.jpg", "http://s23.postimg.org/vvdy69inf/Arts_Crafts_Stamp_set.jpg"])
    CuratedCategory.create_images(playstation_cat_id, playstation_cur_cat.id, ["http://s29.postimg.org/wsyfn3xt3/Girl_Video_Games_Black_Widow.jpg", "http://s28.postimg.org/9tftes759/Girl_Video_Games_Disney_Infinity.jpg", "http://s24.postimg.org/k7m8o30p1/Girl_Video_Games_Voice.jpg", "http://s11.postimg.org/ul2crprgz/Video_Games_controller.jpg"])
  end

  def self.populate_younger_girls_curated_category
    nerf_cat_id = CuratedCategory.get_id_for_cat("Dolls")
    xbox_cat_id = CuratedCategory.get_id_for_cat("Disney")
    clothes_cat_id = CuratedCategory.get_id_for_cat("LEGOs")
    sports_cat_id = CuratedCategory.get_id_for_cat("Arts & Crafts")
    lego_cat_id = CuratedCategory.get_id_for_cat("Stuffed Animals")
    playstation_cat_id =  CuratedCategory.get_id_for_cat("Sports")

    category_group_id = CategoryGroup.where("name='Younger Girls'").first.id

    #now create curated categories
    nerf_cur_cat = CuratedCategory.create(category_id: nerf_cat_id, order_index: 1, category_group_id: category_group_id)
    xbox_cur_cat = CuratedCategory.create(category_id: xbox_cat_id, order_index: 2, category_group_id: category_group_id)
    clothes_cur_cat = CuratedCategory.create(category_id: clothes_cat_id, order_index: 3, category_group_id: category_group_id)
    sports_cur_cat = CuratedCategory.create(category_id: sports_cat_id, order_index: 4, category_group_id: category_group_id)
    lego_cur_cat = CuratedCategory.create(category_id: lego_cat_id, order_index: 5, category_group_id: category_group_id)
    playstation_cur_cat = CuratedCategory.create(category_id: playstation_cat_id, order_index: 6, category_group_id: category_group_id)

    CuratedCategory.create_images(nerf_cat_id, nerf_cur_cat.id, ["http://s15.postimg.org/ysrhfbzu3/Dolls_American_Girl_Clothes.jpg", "http://s15.postimg.org/dyf4xi5gr/Dolls_American_Girl.jpg", "http://s27.postimg.org/rfz2j25pf/Dolls_Ballet_Barbie.jpg", "http://s9.postimg.org/borkhaxan/Dolls_Ever_After.jpg"])
    CuratedCategory.create_images(xbox_cat_id, xbox_cur_cat.id, ["http://s13.postimg.org/76ifg8od3/Disney_Brave_alt_2.jpg", "http://s18.postimg.org/7g7ajc92x/Disney_Elsa_dress.jpg", "http://s23.postimg.org/wjj4e7puz/Disney_Fairy.jpg", "http://s30.postimg.org/tbq4t0qsh/Disney_Olaf.jpg"])
    CuratedCategory.create_images(clothes_cat_id, clothes_cur_cat.id, ["http://s24.postimg.org/srfbk8h8l/Girl_Lego_car.jpg", "http://s29.postimg.org/oivx0ztnr/Girl_Lego_Elves_Pegasus.jpg", "http://s10.postimg.org/jciqsg0pl/Girl_Lego_Treehouse.jpg", "http://s13.postimg.org/kjlkiut7b/Girl_Lego_Unikitty.jpg"])
    CuratedCategory.create_images(sports_cat_id, sports_cur_cat.id, ["http://s14.postimg.org/vnugg145t/Arts_Crafts_bunny.jpg", "http://s17.postimg.org/ffl4345wv/Arts_Crafts_Charm.jpg", "http://s21.postimg.org/54sgg36k7/Arts_Crafts_Friendship_bracelet.jpg","http://s10.postimg.org/8yw5nt121/Arts_Crafts_fruit_bracelet.jpg"])
    CuratedCategory.create_images(lego_cat_id, lego_cur_cat.id, ["http://s22.postimg.org/e66ztvrox/Stuffed_Animal_Boo.jpg", "http://s9.postimg.org/53t3652j3/Stuffed_animal_Fur_real.jpg", "http://s1.postimg.org/69b4gn0tr/Stuffed_animal_minion.jpg", "http://s18.postimg.org/51xshvmd5/Stuffed_animals_Beanie_Boo.jpg"])
    CuratedCategory.create_images(playstation_cat_id, playstation_cur_cat.id, ["http://s12.postimg.org/q94bvuy7x/Girl_sports_pink_blue_bag.jpg", "http://s28.postimg.org/fetiaqa0d/Girl_sports_soccer_cleats.jpg", "http://s9.postimg.org/sbmwvludr/Girl_sports_softball_mitt.jpg", "http://s30.postimg.org/y0sn1jhy9/Girl_Sports_tennis_skirt.jpg"])
  end

  def self.populate_younger_boys_curated_category
    nerf_cat_id = CuratedCategory.get_id_for_cat("Nerf")
    xbox_cat_id = CuratedCategory.get_id_for_cat("Video Games")
    clothes_cat_id = CuratedCategory.get_id_for_cat("Trading Cards")
    sports_cat_id = CuratedCategory.get_id_for_cat("Sports")
    lego_cat_id = CuratedCategory.get_id_for_cat("LEGOs")
    playstation_cat_id =  CuratedCategory.get_id_for_cat("Star Wars")

    category_group_id = CategoryGroup.where("name='Younger Boys'").first.id

    #now create curated categories
    nerf_cur_cat = CuratedCategory.create(category_id: nerf_cat_id, order_index: 1, category_group_id: category_group_id)
    xbox_cur_cat = CuratedCategory.create(category_id: xbox_cat_id, order_index: 2, category_group_id: category_group_id)
    clothes_cur_cat = CuratedCategory.create(category_id: clothes_cat_id, order_index: 3, category_group_id: category_group_id)
    sports_cur_cat = CuratedCategory.create(category_id: sports_cat_id, order_index: 4, category_group_id: category_group_id)
    lego_cur_cat = CuratedCategory.create(category_id: lego_cat_id, order_index: 5, category_group_id: category_group_id)
    playstation_cur_cat = CuratedCategory.create(category_id: playstation_cat_id, order_index: 6, category_group_id: category_group_id)

    CuratedCategory.create_images(nerf_cat_id, nerf_cur_cat.id, ["http://s17.postimg.org/la2ec89xb/Nerf_Ball.jpg", "http://s29.postimg.org/en9eawbmf/Nerf_Blue_gun.jpg", "http://s22.postimg.org/4say0iwu9/Nerf_Bow.jpg", "http://s7.postimg.org/mqp9c606j/nerf_gun2.jpg"])
    CuratedCategory.create_images(xbox_cat_id, xbox_cur_cat.id, ["http://s30.postimg.org/71p8prcf5/young_VG_ipad.png", "http://s4.postimg.org/vxr51tky5/young_VG_skylander.jpg", "http://s18.postimg.org/4zwae0c8p/young_Vg_PS3.png", "http://s7.postimg.org/ktwj3aqqz/young_VG_smash.png"])
    CuratedCategory.create_images(clothes_cat_id, clothes_cur_cat.id, ["http://s28.postimg.org/e06mtzay5/young_trading_dez.png", "http://s4.postimg.org/wi664ie6l/young_trading_charizard2.png", "http://s12.postimg.org/3ylzcdo71/young_trading_bumgarner.png", "http://s14.postimg.org/hy0u400ap/young_trading_charizard.png"])
    CuratedCategory.create_images(sports_cat_id, sports_cur_cat.id, ["http://s13.postimg.org/qxxpts3dz/older_sports_crosby.png", "http://s15.postimg.org/kvxj0ln17/older_sports_skateboard.png", "http://s15.postimg.org/wstqytecb/older_sports_snowboard.png", "http://s2.postimg.org/wfwdsocbd/older_sports_sneakers.png"])
    CuratedCategory.create_images(lego_cat_id, lego_cur_cat.id, ["http://s3.postimg.org/r9ekorboj/young_lego_LOTR.png", "http://s21.postimg.org/6metue96f/young_lego_ninjago.png", "http://s3.postimg.org/bpbsbyqxv/young_lego_sensei.png", "http://s14.postimg.org/sarq3tj7l/young_lego_atat.png"])
    CuratedCategory.create_images(playstation_cat_id, playstation_cur_cat.id, ["http://s21.postimg.org/4w0e6nh13/young_SW_chewbacca.jpg", "http://s15.postimg.org/j4skxewx7/young_SW_Chewbacca2.jpg", "http://s30.postimg.org/dtyhuybvl/young_SW_vader.jpg", "http://s17.postimg.org/rbhjpokj3/young_SW_Falcon.png"])
  end

  def self.populate_curated_categories
    CuratedCategory.populate_younger_boys_curated_category
    CuratedCategory.populate_older_boys_curated_category
    CuratedCategory.populate_younger_girls_curated_category
    CuratedCategory.populate_older_girls_curated_category
  end

  def self.get_id_for_cat(name)
    low_case = name.downcase
    cat = Category.where("name LIKE '%" + low_case + "%'").first
    if cat.nil?
      new_cat = Category.create(name: name, level: 1, male_index: 0, female_index: 0, icon_label: name, male_hides_name: false, female_hides_name: false, male_age_group: "", female_age_group: "", male_icon_background_color: "#facf22", female_icon_background_color: "#facf22")
      result = new_cat.id
    else
      result = cat.id
    end
    result
  end

  def self.force_cat_id_for_cat(name)
    low_case = name.downcase
    new_cat = Category.create(name: name, level: 1, male_index: 0, female_index: 0, icon_label: name, male_hides_name: false, female_hides_name: false, male_age_group: "", female_age_group: "", male_icon_background_color: "#facf22", female_icon_background_color: "#facf22")
    new_cat.id
  end

  def self.create_images(cat_id,cur_cat_id, img_array)
    #::Items::CategoryCuratedItem.create_sample_item(3, 200003, {price: 2, description: "heyo", item_photos: {[url: "http://s16.postimg.org/rvdtvcb51/Nerf_Ball.jpg"]}})
    img_array.each do |img_url|
      ::Items::CategoryCuratedItem.create_sample_item(cur_cat_id, cat_id, {price: 2, description: "populated", item_photos: [{url: img_url}]})
    end
  end


  protected

  def set_defaults!
    cc = self.class.where(category_group_id: category_group_id).order('order_index desc').first
    self.order_index = (cc.try(:order_index) || 0 ) + 1

  end
end
