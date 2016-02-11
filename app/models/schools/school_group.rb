##
# Defined relationships between users: mainly classmates
module Schools
  class SchoolGroup < ActiveRecord::Base
    self.table_name = 'schools_users'

    attr_accessible :user_id, :school_id, :teacher, :grade

    has_many :users
    belongs_to :user

    after_save :apply_user_settings!

    # Grade for names
    PRE_KINDERGARDEN = 100
    KINDERGARDEN = 101
    COLLEGE = 18

    GRADES_HASH = ::ActiveSupport::OrderedHash.new
    GRADES_HASH[PRE_KINDERGARDEN] = 'Pre-K'
    GRADES_HASH[KINDERGARDEN] = 'Kindergarden'
    1.upto(12) {|i| GRADES_HASH[i] = i.ordinalize + ' Grade' }
    GRADES_HASH[COLLEGE] = 'College'

    AGE_BEFORE_ELEMENTARY = 5

    ##
    # @return <Array of grades in range>
    def self.grades_around(grade)
      return 1.upto(12).to_a if grade.nil?
      if grade.eql?(KINDERGARDEN)
        oldgrade = KINDERGARDEN
        grade = 1
      else
        oldgrade = grade
      end
      if grade.eql?(PRE_KINDERGARDEN)
        result = [PRE_KINDERGARDEN, KINDERGARDEN]
      elsif grade.between?(1, 12)
        result = [grade - 1, grade, grade + 1].delete_if{|g| g < 1 || g > 12 }
      else
       result = [COLLEGE]
      end
      grade = oldgrade
      if grade.eql?(1) #add kindergarden
        result << KINDERGARDEN
      end
      result 
    end

    # @return <Range> If grade is invalid, range would only be 0..0
    def self.grade_to_age_range(grade)
      return 0..0 if grade.to_i < 1
      if grade == PRE_KINDERGARDEN
        1..3
      elsif grade == KINDERGARDEN
        4..AGE_BEFORE_ELEMENTARY
      elsif grade >= 1 && grade <= 12
        (AGE_BEFORE_ELEMENTARY + grade)..17
      else
        18..100
      end
    end

    # @return <Integer>
    def self.age_to_grade(age)
      if age.to_i >= 18
        COLLEGE
      elsif ((AGE_BEFORE_ELEMENTARY + 1)..17).include?(age)
        age - AGE_BEFORE_ELEMENTARY
      elsif (4..AGE_BEFORE_ELEMENTARY).include?(age)
        KINDERGARDEN
      else
        PRE_KINDERGARDEN
      end
    end
    
    def self.student_count(school)
        result = select("school_id, count(*) as c").group("school_id").where(school_id: school.id).first
        result.nil? ? 0 : result["c"]
    end
    
    # @school_id <integer> optional. If given, would specifically question being schoolmates of exact school.
    def self.are_schoolmates?(first_user_id, second_user_id, school_id = nil)
      conds = school_id.present? ? {school_id: school_id} : {}
      first_school_ids = where(conds.merge(user_id: first_user_id)).select('school_id').collect(&:school_id)
      second_school_ids = where(conds.merge(user_id: second_user_id)).select('school_id').collect(&:school_id)
      (first_school_ids & second_school_ids).present?
    end

    def self.get_schoolmates(user_id)
      school_ids = where(user_id: user_id).select('school_id').collect(&:school_id)
      school_ids.present? ? where("school_id IN (?)", school_ids).collect(&:user) : []
    end

    ##
    # After save call to update the user's attributes according to this school
    def apply_user_settings!
      user.update_attributes(current_school_id: self.school_id, teacher: self.teacher, grade: self.grade)
    end

  end
end
