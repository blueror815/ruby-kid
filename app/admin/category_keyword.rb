ActiveAdmin.register CategoryKeyword do
	filter :category_id
	filter :keyword
	index do
		column :category_id
		column :keyword
		actions
	end

	show do
		attributes_table do
			row :keyword
			row :category_id do |catkeyword|
				link_to(catkeyword.category_id, administrator_category_path(id: catkeyword.category_id)).html_safe
			end
			row :category_name do |catkeyword|
				category = Category.where(id: catkeyword.category_id).first
				category.name
			end
		end
	end

	form do |f|
		f.inputs "Details" do 
			f.input :category_id
			f.input :keyword
		end
		f.actions
	end

end
