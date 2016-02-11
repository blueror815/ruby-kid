##
# The model records that have bad word matches and store original text and
# word matches.
module Filters
  class FilteredRecord < ::ActiveRecord::Base
    self.table_name = 'filtered_records'

    include ::Filters::ContentType

    attr_accessible :user_id, :content_type, :content_type_id, :text_attribute, :original_text, :matches,
                    :status_code

    STATUS_CODES_MAP = { -10 => 'OMITTED', 0 => 'NEW', 10 => 'REVIEWED_BY_PARENT', 20 => 'REVIEWED_BY_ADMIN' }

    MATCH_REPLACEMENT_CHARS = ''
    MATCHES_WORD_SEPARATOR = "\n"

    belongs_to :user

    def content_record(*includes)
      if self.class.valid_content_type?(content_type_id) && content_type_id.to_i > 0
        query = self.class.content_type_class(content_type).where(id: content_type_id)
        query = query.includes(includes) if includes.present?
        query.first
      else
        nil
      end
    rescue
      nil
    end

    def viewable_by_user?(user)
      user.is_a?(Admin) || user_id == user.id || user.parent_of?(user)
    end

    ###########################
    # Class Methods

    ##
    # @param content <any model class of ActiveRecord::Base>
    # @param attribute_list <Array of attribute names>
    # @return <Array of FilteredRecord>
    def self.filter(user_id, _content_record, attribute_list)
      created_filtered_records = []
      all_offenses = []
      attribute_list.each do|attr|
        t = _content_record[attr.to_s].strip_acronymns
        offenses = Obscenity.offensive( t )
        if offenses.present?
          created_filtered_records << create(user_id: user_id, content_type: _content_record.class.to_s, content_type_id: _content_record.id,
                 text_attribute: attr, original_text: t, matches: offenses.join(MATCHES_WORD_SEPARATOR)
          )
          _content_record[attr.to_s] = ::Obscenity.replacement(MATCH_REPLACEMENT_CHARS).sanitize(t.clone)
          all_offenses = all_offenses + offenses

        end
      end
      _content_record.status = 'REPORT_SUSPENDED' if _content_record.respond_to?(:status) && all_offenses.present?
      _content_record.save if _content_record.changed?
      created_filtered_records
    end

  end
end