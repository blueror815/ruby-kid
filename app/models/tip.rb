class Tip < ActiveRecord::Base
  attr_accessible :title, :order_index

  before_create :set_defaults!


  def set_defaults!
    if self.order_index.nil? || self.order_index <= 1
      max_record = self.class.order('order_index desc').first
      self.order_index = max_record ? max_record.order_index + 1 : 1
    end
  end
end
