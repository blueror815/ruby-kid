module Users
  class ChildCircleOption < Boundary

    CIRCLE_OPTIONS_MAP = ::ActiveSupport::OrderedHash.new
    CIRCLE_OPTIONS_MAP['ONE_GRADE_AROUND'] = '+/- A Grade'
    CIRCLE_OPTIONS_MAP['GRADE_ONLY'] = 'Grade Only'
    CIRCLE_OPTIONS_MAP['CLASS_ONLY'] = 'Class Only'

    def content_record
      content_keyword
    end

    def self.content_value_column
      'content_keyword'
    end

  end
end
