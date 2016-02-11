module Users
  class Boundary < ActiveRecord::Base
    
    attr_accessible :type, :user_id, :content_type_id, :content_keyword

    belongs_to :user, class_name: '::User'

    CACHE_EXPIRATION_LENGTH = 6.hours.to_i

    scope :child_circle_options, conditions: { type: 'Users::ChildCircleOption' }
    scope :user_blocks, conditions: { type: 'Users::UserBlock' }
    scope :keyword_blocks, conditions: { type: 'Users::KeywordBlock' }
    scope :category_blocks, conditions: { type: 'Users::CategoryBlock' }

    ##
    # Draft version.  Should be implemented in subclass where the record type is defined.
    def content_record
      nil
    end

    # Should be implemented in subclass where the record type is defined
    def self.content_value_column
      'content_type_id'
    end

    def content_value
      self.attributes[self.class.content_value_column]
    end

    def as_json(options = {})
      h = super(options.merge(only: [:id, :type, :user_id, :created_at] ) )
      h[:content_value] = self.content_value
      h
    end


    ##
    # type_class <SubClass of Boundary>
    # ids <Array of either all integer ids or all String keywords>
    # @return <Array of Boundary created>
    def self.add!(user_id, type_class, ids)
      return [] if ids.blank?

      # Invalidate cache
      expire_boundaries!(user_id)

      list = []
      if type_class.content_value_column == :content_keyword
        ids.each do|id|
          list << type_class.create(user_id: user_id, content_keyword: id.to_s) if id.to_s.present?
        end
      else
        ids.each do|id|
          list << type_class.create(user_id: user_id, content_type_id: id)
        end
      end
      list
    end

    ##
    # type_class <Class>
    # ids <Array of either all integer ids or all String keywords>

    def self.remove!(user_id, type_class, ids)

      expire_boundaries!(user_id)

      if ids_to_block.first.is_a?(String)
        delete_all(user_id: user_id, type: type_class.to_s, content_keyword: ids)
      else
        delete_all(user_id: user_id, type: type_class.to_s, content_type_id: ids)
      end
    end

    ##
    # @return <Array of JSON values, each of which is the hash of the Boundary object>
    def self.get_boundaries(user_id, use_cache = true)
      cache_key = make_cache_key(user_id)
      result = if use_cache
                 res = $redis.get(cache_key).to_s
                 # logger.info "| Get cache? #{use_cache} ... user_blocks of #{user_id} => #{res} |"
                 res.present? ? JSON.parse(res) : nil
               else
                 nil
               end

      unless result
        result = where(user_id: user_id)

        $redis.set cache_key, result.to_json
        $redis.expire cache_key, CACHE_EXPIRATION_LENGTH
      end
      result
    end

    def self.expire_boundaries!(user_id)
      logger.info "| Expiring ... user_blocks of #{user_id}"
      $redis.del make_cache_key(user_id)
    end

    ##
    # Exact values of just this type
    def self.get_content_values(user_id, boundary_class, use_cache = true)
      values = []
      get_boundaries(user_id, use_cache).each do|b|
        if b.is_a?(boundary_class)
          values << b.content_value
        end
      end
      values
    end

    ##
    # blist <Array of Boundary or Integer or String>
    def self.extract_content_values_from_list(blist)
      blist.collect {|b| b.is_a?(::Users::Boundary) ? b.content_value : b }
    end


    protected

    def self.make_cache_key(user_id)
      "boundaries/#{user_id}"
    end


  end
end
