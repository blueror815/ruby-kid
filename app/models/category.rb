class Category < ActiveRecord::Base
  attr_accessible :full_path_ids, :level, :level_order, :name, :icon_label, :parent_category_id, :male_index, :female_index,
                  :male_icon, :male_camera_background, :male_icon_background_color, :male_hides_name,
                  :female_icon, :female_camera_background, :female_icon_background_color, :female_hides_name,
                  :male_age_group, :female_age_group
  attr_accessor :keywords, :category_group_id
  alias_attribute :title, :name

  cache_records :store => :shared, :key => "cat"

  DEFAULT_GENDER_INDEX = 1

  belongs_to :parent_category, :class_name => 'Category', :foreign_key => :parent_category_id
  has_many :subcategories, :class_name => 'Category', :foreign_key => :parent_category_id
  has_many :category_curated_items, :class_name => 'Items::CategoryCuratedItem'
  belongs_to :category_group

  mount_uploader :male_icon, ::ImageUploader
  mount_uploader :male_camera_background, ::ImageUploader
  mount_uploader :female_icon, ::ImageUploader
  mount_uploader :female_camera_background, ::ImageUploader

  scope :top_categories, where(:level => 1).order('level_order ASC')
  scope :for_user, lambda { |user|
    user.female? ? where("female_index > 0").order('female_index ASC') : where("male_index > 0").order('male_index ASC')
  }

  searchable do
    text :name
    integer :level
    string :gender_group do
      gender_group
    end
  end

  #########################

  # Scans from bottom to top level
  # @return <List>

  before_save :validate_attributes
  after_save :set_category_group!
  after_save :set_full_path_ids!


  # Could get this from full_path_ids if that attribute is reliably set.
  # The order of list is by levels top to bottom.
  def all_categories_to_top
    list = []
    # Never figured out inject
    current = self
    while current.present?
      list.prepend current
      current = current.nil? ? nil : current.parent_category
    end
    list.flatten!
    list
  end

  # Set full_path_ids as way to store full path of category hierarchy as comma separated IDs string
  def set_full_path_ids!
    if parent_category_id.to_i > 0
      all_categories_to_top.collect { |c| c.id.to_s }.join(',')
    else
      self.full_path_ids = id.to_s
    end
  end

  def for_male?
    male_index.to_i > 0
  end

  def for_female?
    female_index.to_i > 0
  end

  ##
  # ====
  # return <String>
  def camera_background_for(current_user)
    url = for_male? ? male_camera_background_url : nil
    url ||= for_female? ? female_camera_background_url : nil
    url
  end

  ##
  # The value when category is set for male
  def selected_male_index
    male_index.to_i > 0 ? male_index : DEFAULT_GENDER_INDEX
  end

  ##
  # The value when category is set for female
  def selected_female_index
    female_index.to_i > 0 ? female_index : DEFAULT_GENDER_INDEX
  end

  ##
  # Either 'M', 'F' or 'MF'

  def gender_group
    gender_group = ''
    gender_group << 'M' if for_male?
    gender_group << 'F' if for_female?
    gender_group = 'MF' if gender_group.blank?
    gender_group
  end

  def as_json(options = nil)
    { id: id, name: name, icon_label: icon_label.to_s, gender_group: gender_group, male_sort_order: male_index, female_sort_order: female_index,
      male_icon_url: male_icon_url.to_s, male_camera_background_url: male_camera_background_url.to_s,
      male_icon_background_color: male_icon_background_color.to_s, male_hides_name: male_hides_name,
      female_icon_url: female_icon_url.to_s, female_camera_background_url: female_camera_background_url.to_s,
      female_icon_background_color: female_icon_background_color.to_s, female_hides_name: female_hides_name
    }
  end

  def set_category_group!
    if category_group_id.to_i > 0
      assign_to_category_group!(category_group_id)
    end
  end

  ##
  # Add to CategoryGroup.categories if not exists; set Category's gender index (male_index or female_index) and
  # gender age group (male_age_group or female_age_group).
  # @category_group_or_id <either ID or actual CategoryGroup object>
  # @mapping_param <Hash> extra attributes to assign to CategoryGroupMapping
  # @return <CategoryGroupMapping> whether it was added or already exists
  def assign_to_category_group!(category_group_or_id, mapping_param = {})
    category_group = category_group_or_id.is_a?(::CategoryGroup) ? category_group_or_id : ::CategoryGroup.find_by_id(category_group_or_id)
    category_group_mapping = nil
    if category_group
      unless category_group.category_group_mappings.collect(&:category_id).include?(id)
        h = mapping_param.merge({ category_group_id: category_group.id, category_id: id,
                                  order_index: (category_group.category_group_mappings.collect(&:order_index).max || 0) + 1  })
        category_group_mapping = ::CategoryGroupMapping.new(h)
        category_group.category_group_mappings << category_group_mapping
        category_group.save
        logger.info ">> Adding mapping to group #{category_group.id}: #{h}"
      end
    end
    category_group_mapping
  end


  ########
  # Class Methods

  ##
  # Determine matching CategoryGroup for the user.
  # @return < ActiveRecord::Relation >
  def self.for_user_from_category_groups(user)
    if (g = ::CategoryGroup.for_user(user))
      g.categories
    else
      self.for_user(user)
    end
  end


  ##
  # @categories <Array of Category>
  # @which_attribute <String or Symbol> which Category attribute to change
  # @up_direction <boolean> whether it's up or down direction
  def self.reorder_categories(category, which_attribute, up_direction = true)
    cats = Category.where("#{which_attribute} != 0").order("#{which_attribute} asc").to_a
    if (index = cats.index(category) )
      cats.delete_at(index)
      cats.insert( up_direction ? (index - 1) : (index + 1), category ).each_with_index do |c, idx|
        logger.info "| #{c.name} - #{idx + 1} for #{which_attribute}"
        c.update_attribute(which_attribute, idx + 1)
      end
    end
  end

  private

  ##
  # Sets gender group to be both for boys and girls if neither selected.  And clears away images of a gender if de-selected.
  def validate_attributes
    if male_index_changed? && !for_male?
      self.remove_male_icon! if self.male_icon
      self.remove_male_camera_background! if self.male_camera_background
    end
    if female_index_changed? && !for_female?
      self.remove_female_icon! if self.female_icon
      self.remove_female_camera_background! if self.female_camera_background
    end
    self.male_icon_background_color = '#' + male_icon_background_color if male_icon_background_color.present? && !male_icon_background_color.starts_with?('#')
    self.female_icon_background_color = '#' + female_icon_background_color if female_icon_background_color.present? && !female_icon_background_color.starts_with?('#')
  end

end
