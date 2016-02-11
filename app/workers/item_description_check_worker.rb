class ItemDescriptionCheckWorker
  include Sidekiq::Worker
  #create a perform method.

  def perform(string_to_search, category_id, item_id)
    Item.check_desc_for_associations!(string_to_search, category_id, item_id)
  end
end
