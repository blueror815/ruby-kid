module Schools
  class SchoolRegistration < ::ActiveRecord::Base
    self.table_name = 'schools_users'

    attr_accessible :user_id, :school_id, :teacher, :grade

    belongs_to :school, class_name:'Schools::School', dependent: :destroy
    belongs_to :user, dependent: :destroy

    after_create :update_school_user_count!

    validates_presence_of :user_id, :school_id

    protected

    def update_school_user_count!
      if self.school_id.to_i > 0
        cnt = self.class.count(:user_id, distinct: true, conditions: "school_id = #{self.school_id}" )
        ::Schools::School.update_all("user_count = #{cnt}", "id = #{self.school_id}")
      end
    end

  end
end