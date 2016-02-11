ActiveAdmin.register AssociatedCategory do
	actions :all, :except => [:new]
	
	filter :category_id
	filter :item_id
	index do
		column :item_id
		column :category_id
		actions
	end

	show do
		attributes_table do
			row :category do |associated_cat|
				link_to(associated_cat.category_id, administrator_category_path(id: associated_cat.category_id)).html_safe
			end
			row :category_name do |associated_cat|
				category = Category.where(id: associated_cat.category_id).first
				category.name
			end
			row :item do |associated_cat|
				link_to(associated_cat.item_id, administrator_item_path(id: associated_cat.item_id)).html_safe
			end
			row :item_name do |associated_cat|
				item = Item.where(id: associated_cat.item_id).first
				item.title
			end
		end
	end
end
