module Users
  class Relationship < ActiveRecord::Base
    self.table_name = 'user_relationships'
    
    attr_accessible :primary_user_id, :secondary_user_id, :relationship_type
    
    belongs_to :primary_user, :class_name => 'User'
    belongs_to :secondary_user, :class_name => 'User'
    
    object_constants :relationship_type, :father, :mother, :guardian, :child, :friend
    
    PARENTS = [RelationshipType::FATHER, RelationshipType::MOTHER, RelationshipType::GUARDIAN]

    scope :parenthood, conditions:{ relationship_type: PARENTS }
    
    def parent?
      PARENTS.include?(relationship_type.to_s.upcase)
    end
    
    def guardian?
      RelationshipType::GUARDIAN == relationship_type
    end
    
    def friend?
      RelationshipType::FRIEND == relationship_type
    end
  end
end