class ItemKeyword < ActiveRecord::Base
  attr_accessible :item_id, :keyword
  
  belongs_to :item
end
