module Users
  class CategoryBlock < Boundary

    self.table_name = 'boundaries'

    alias_attribute :blocker_user_id, :user_id
    alias_attribute :category_id, :content_type_id
    
    belongs_to :category, class_name: '::Category', foreign_key: 'content_type_id'    

    def content_record
      category
    end

  end
end
