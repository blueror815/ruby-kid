module Jobs
  class ItemDescriptionCheck < ItemCheck

    def perform
      BG_LOGGER.info "#{self.class.to_s} for item #{item_id}"
      ::Item.check_desc_for_associations!(item.description, item.category_id, item.id)
    end
  end

end