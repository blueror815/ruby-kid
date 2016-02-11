class FilterRecordWorker
  include Sidekiq::Worker

  ##
  # @content_type <String, class name>
  # @content_type_id <Integer, the id of the model>

  def perform(user_id, content_type, content_type_id, attributes_list)
    if ::Filters::FilteredRecord.valid_content_type?(content_type) && content_type_id.to_i > 0
      record = content_type.constantize.find_by_id(content_type_id)
      if record
        logger.info "-> Filtering #{content_type}(#{content_type_id}).#{attributes_list}"
        ::Filters::FilteredRecord.filter(user_id, record, attributes_list)
      end
    end
  rescue Exception => e
    logger.warn "** #{e.message}\n" << e.backtrace.join("\n\t")
  end

end