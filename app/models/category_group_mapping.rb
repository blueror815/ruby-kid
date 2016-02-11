##
# Joining entries between CategoryGroup and Categories mainly for browsing and posting paths.  This is different from
# CategoryCuratedCategory that is separate set of join entries for Welcome Kid path to use.

class CategoryGroupMapping < ::ActiveRecord::Base
  self.table_name = 'category_groups_categories'

  attr_accessible :category_group_id, :category_id, :order_index, :icon, :icon_background_color, :camera_background

  validates_presence_of :category_group_id, :category_id

  belongs_to :category_group, dependent: :destroy
  belongs_to :category, dependent: :destroy

  mount_uploader :icon, ::ImageUploader
  mount_uploader :camera_background, ::ImageUploader

  ##
  # Corresponding CuratedCategory with same category_group and category
  def curated_category
    @curated_category ||= ::CuratedCategory.where(category_group_id: category_group_id, category_id: category_id).first ||
        ::CuratedCategory.new(category_group_id: category_group_id, category_id: category_id)
  end

  ##
  # Corresponding CategoryCuratedItems on the same category_group and corresponding currated_category
  def category_curated_items
    logger.info "| Mapping: category_id #{category_id}"
    logger.info "| #{category_group}"
    logger.info "--| curated cats: #{category_group.curated_categories}"
    logger.info "--| curated_category #{curated_category} w/ #{curated_category.category_curated_items}"
    curated_category ? curated_category.category_curated_items : []
  end

  # Override category's attributes
  def mapped_category
    @category ||= self.category

    if category_group.for_female?
      @category.male_index = nil
      @category.female_index = order_index if order_index
      @category.female_icon = icon if icon
      @category.female_icon_background_color = icon_background_color if icon_background_color.present?
      @category.female_camera_background = camera_background if camera_background
    else
      @category.female_index = nil
      @category.male_index = order_index if order_index
      @category.male_icon = icon if icon
      @category.male_icon_background_color = icon_background_color if icon_background_color
      @category.male_camera_background = camera_background if camera_background
    end
    @category
  end

end