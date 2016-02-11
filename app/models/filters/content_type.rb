##
# Common module with methods to handle models that have dynamic record type reference using attributes
# :content_type and :content_type_id.
module Filters
  module ContentType



    def self.included(klass)
      klass.extend ContentTypeClassMethods
    end

    def content_type_name
      ct = content_type.to_s.upcase
      case ct
        when 'ITEM_COMMENT'
          'Comment'
        else
          ct.humanize.downcase
      end
    end

    def content_record(*includes)
      if self.class.valid_content_type?(content_type) && content_type_id.to_i > 0
        query = self.class.content_type_class(content_type).where(id: content_type_id)
        query = query.includes(includes) if includes.present?
        query.first
      else
        nil
      end
    rescue
      nil
    end

    protected

    ##
    # Generate error if needed
    def check_attributes
      unless self.class.valid_content_type?(content_type)
        self.errors.add(:content_type, "Invalid content type")
      end
    end
  end

  ###################
  #
  module ContentTypeClassMethods

    object_constants :valid_content_type, :user, :item, :item_comment, :trade_comment
    
    ##
    # @return <bool>
    def valid_content_type?(content_type)
      ct = content_type.to_s.gsub(/((::)?(\w+::)+)/i, '')
      VALID_CONTENT_TYPES.collect(&:to_s).include?(ct.underscore.upcase)
    end

    ##
    # @return <NilClass or the corresponding model class>  If invalid, NilClass would be returned.
    def content_type_class(content_type)
      return NilClass if not valid_content_type?(content_type)
      (content_type =~ /trade_comment/i ) ? ::Trading::TradeComment : content_type.downcase.classify.constantize
    end
  end
end