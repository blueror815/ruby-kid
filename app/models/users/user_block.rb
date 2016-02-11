##
# The record where a user blocks another user
module Users
  class UserBlock < Boundary

    self.table_name = 'boundaries'

    alias_attribute :blocker_user_id, :user_id
    alias_attribute :object_user_id, :content_type_id

    belongs_to :object_user, class_name: '::User', foreign_key: 'content_type_id'

    def content_record
      object_user
    end

    def as_json(options = {})
      h = super(options)
      user_id = h[:content_value]
      h[:content_value] = User.find(user_id).user_name
      h
    end

    ##
    # @return <Array of integer, user IDs>
    def self.add_to_user_blocks!(user_id, users_to_block)
      user_ids_to_block = users_to_block.first.is_a?(User) ? users_to_block.collect(&:id) : users_to_block
      add!(user_id, self, user_ids_to_block)
    end

    def self.remove_from_user_blocks!(user_id, users_to_block)
      user_ids_to_block = users_to_block.first.is_a?(User) ? users_to_block.collect(&:id) : users_to_block

      expire_boundaries!(user_id)

      delete_all(user_id: user_id, content_type_id: user_ids_to_block)
    end

    ##
    # Grab only the user block
    def self.get_user_block_ids(user_id, use_cache = true)
      get_content_values(user_id, self, use_cache)
    end


  end
end
