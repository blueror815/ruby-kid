class CategoryGroupMappingsController < InheritedResources::Base

  def update
    logger.info "Updating mapping for category group #{resource.category_group}"
    update_curated_items(resource)
    super( location: "/admin/categories?t=#{Time.now.to_i}" )
  end

  private

  ##
  # Save given params :curated_item_image or curated_item_id to corresponding CuratedCategory's CategoryCuratedItems.
  # If no curated items found, the
  def update_curated_items(mapping)
    uploaded_images = params[:curated_item_image] || []
    curated_item_ids = params[:curated_item_id] || []
    logger.info "| upload_images: #{uploaded_images}"
    if uploaded_images.present? || curated_item_ids.present?
      if (curated_category = mapping.curated_category)
        curated_category.category_curated_items.delete_all
      else
        curated_category = CuratedCategory.new(category_group_id: mapping.category_group_id,
          category_id: mapping.category_id, order_index: mapping.order_index)
      end
      logger.info "------------- Curated category: #{curated_category}"
      new_curated_items = []
      0.upto(3).each do|idx|
        if ( uploaded_image = uploaded_images[idx] ) && uploaded_image.is_a?(ActionDispatch::Http::UploadedFile)
          citem = ::Items::CategoryCuratedItem.create_sample_item(mapping.category_id, mapping.category_id,
                                                                  item_photos:[uploaded_image] )
          new_curated_items << citem
          logger.info ">> Created sample curated item: #{citem} for CategoryGroup #{mapping}"
        elsif (item_id = curated_item_ids[idx].to_i ) > 0
          if (item = Item.find_by_id(item_id))
            citem = ::Items::CategoryCuratedItem.new(item_id: item.id, category_id: mapping.category_id, curated_category_id: curated_category.id )
            new_curated_items << citem
            logger.info ">> Connecting item #{item_id} to category #{mapping.category_id}, category_group #{mapping.category_group_id}"
          end
        end
      end
      if new_curated_items.size > 0
        curated_category.category_curated_items = new_curated_items
        curated_category.save
      else
        curated_category.destroy if not curated_category.new_record?
      end
    end
  end
end