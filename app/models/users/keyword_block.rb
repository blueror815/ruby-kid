module Users
  class KeywordBlock < Boundary

    alias_attribute :blocker_user_id, :user_id

    def content_record
      content_keyword
    end

    def self.content_value_column
      'content_keyword'
    end

  end
end
