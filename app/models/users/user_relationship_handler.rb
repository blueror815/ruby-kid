module Users
  module UserRelationshipHandler
    # Adds child onto the list of children, and saves itself, therefore, saving the passed-in child instance as well.
      # No logical or duplication check is done.
      # @return <Boolean> Whether the child is validly added.
      def add_child!(child, relationship_type = nil, validate = true)
        validate_create_child(child) if validate

        relationship_type ||= ::Users::Relationship::RelationshipType::GUARDIAN
        if child.errors.count == 0
          save_user_relationship!(child.id, relationship_type ) if relationship_type.present?
          children << child
        else
          false
        end
      end
    
      # Validates whether the coming child already exists by checking user_name and first_name.  Errors will be added to 
      # the child.
      # @return <Boolean> Whether child is validly saved
      def validate_create_child(child)
        child.errors.add(:user_name, "A child with this User Name already created.") if children.collect(&:user_name).include?(child.user_name.strip)
        child.errors.add(:first_name, "A child with this First Name already created.") if children.collect(&:first_name).include?(child.first_name.strip)
      end
    
      # Use this instead of parent.children << child so the relationship_type can be specified.
      # @return <Boolean> where the update is valid
      def save_user_relationship!(secondary_user_id, _type)
        return false if not ::Users::Relationship::RELATIONSHIP_TYPES.include?(_type.to_s.upcase.to_sym)
        relat = ::Users::Relationship.where(primary_user_id: self.id, secondary_user_id: secondary_user_id).first
        relat ||= ::Users::Relationship.create(primary_user_id: self.id, secondary_user_id: secondary_user_id, relationship_type: _type.upcase)
        relat.relationship_type = _type
        relat.save
      end
  end
end
