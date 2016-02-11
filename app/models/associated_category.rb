class AssociatedCategory < ActiveRecord::Base

	attr_accessible :item_id, :category_id

	searchable do 
		integer :category_id
		integer :item_id
	end

	def to_i
		self.category_id
	end

end