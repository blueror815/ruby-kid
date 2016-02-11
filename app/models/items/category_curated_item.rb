module Items
  class CategoryCuratedItem < ::ActiveRecord::Base

    attr_accessible :curated_category_id, :item_id, :category_id
    self.table_name = 'category_curated_items'

    belongs_to :category
    belongs_to :item
    belongs_to :curated_category

    ##
    # @params <Hash of Item attributes> :item_photos would be needed.
    # @return <Items::CategoryCuratedItem>
    def self.create_sample_item(curated_category_id, category_id, params = {})
      raise ::Exception.new("At least some item attributes are required") if params.blank?

      params[:description] = 'Sample item' if params[:description].blank?
      item_photos = params.delete(:item_photos)
      item = Item.new(params)
      item.user_id = ::Admin.cubbyshop_admin.id
      item.category_id = category_id
      item.price ||= 1.0
      logger.info " .. creating sample item.  valid? #{item.valid?}  #{item.errors.full_messages}"
      item.save
      item.load_item_photos_with_params({item_photos: item_photos})
      create(category_id: category_id, item_id: item.id, curated_category_id: curated_category_id)
    end

  end
end
