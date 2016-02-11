##
# Flexible / dynamic record-type filter to sanitize record's specified attributes.
# Must set arguments user_id, content_type, content_type_id, attributes_list
module Jobs
  class RecordFilter < Struct.new(:user_id, :content_type, :content_type_id, :attributes_list)

    TIME_LENGTH = 10.seconds

    #######################
    # Delayed job methods

    def perform
      BG_LOGGER.info self.to_s
      if ::Filters::FilteredRecord.valid_content_type?(content_type) && content_type_id.to_i > 0
        record = content_type.constantize.find_by_id(content_type_id)
        if record
          ::Filters::FilteredRecord.filter(user_id, record, attributes_list)
        else
          BG_LOGGER.info "** Cannot find #{self}"
        end
      end
    end

    def max_attempts
      3
    end

    def queue_name
      'trade_comment_checks_queue'
    end


    def enqueue!
      Delayed::Job.enqueue( self, priority: 0, run_at: TIME_LENGTH.from_now)
    end

    def to_s
      "#{self.class.to_s} for content #{content_type}(#{content_type_id}) #{attributes_list} of user #{user_id}"
    end

  end
end