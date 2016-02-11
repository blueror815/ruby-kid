class CategoryGroup < ::ActiveRecord::Base

  attr_accessible :name, :gender, :lowest_age, :highest_age, :country

  has_many :curated_categories
  has_many :category_group_mappings, class_name:'CategoryGroupMapping'
  has_and_belongs_to_many :categories, join_table: 'category_groups_categories'

  validates_presence_of :name

  def for_female?
    gender.upcase == 'FEMALE'
  end

  def for_male?
    gender.upcase == 'MALE'
  end

  # Whether male_index or female_index
  # @return <Symbol>
  def gender_index
    for_female? ? :female_index : :male_index
  end

  def age_group_to_s
    "#{lowest_age} - #{highest_age}"
  end

  def sample_child
    Child.new(gender: gender, grade: ::Schools::SchoolGroup.age_to_grade(lowest_age) )
  end

  def to_s
    '[CategoryGroup(%d) %s, gender %s, %s..%s]' % [id, name, gender, lowest_age.to_s, highest_age.to_s]
  end

  ##
  # @return <CategoryGroup> If match not found, would return nil.
  def self.for_user(user)
    age_range = ::Schools::SchoolGroup.grade_to_age_range(user.grade)
    matching_group = nil
    order('highest_age asc').all.each do|g|
      g.highest_age ||= 100
      if (g.lowest_age..g.highest_age).include?(age_range.begin)
        if g.gender.blank? || g.gender.upcase == user.gender.to_s.upcase
          matching_group = g
          break
        end
      end
    end
    matching_group
  end
end
