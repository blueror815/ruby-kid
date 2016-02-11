ActiveAdmin.register Category do
	config.filters = false
	index do
		id_column
		column :name
		column :male_icon do |category|
			icon_link = category.male_icon.to_s
			if icon_link.eql? ""
				"No Icon"
			elsif not icon_link.include? "http"
				icon_link = "http://kidstrade.com" + icon_link.to_s
				icon_link.gsub(":ImageUploader", "")
				image_tag(icon_link, size:"50x50")
			else
				image_tag(icon_link, size:"50x50")
			end
		end
		column :female_icon do |category|
			icon_link = category.female_icon.to_s
			if icon_link.eql? ""
				"No Icon"
			elsif not icon_link.include? "http"
				icon_link = "http://kidstrade.com" + icon_link.to_s
				icon_link.gsub(":ImageUploader", "")
				image_tag(icon_link, size:"50x50")
			else
				image_tag(icon_link, size:"50x50")
			end
		end
		actions
	end

	show do
		attributes_table do
			row :id
			row :title
			row :name
			row :created_at
			row :updated_at
			row :male_icon do |category|
				icon_link = category.male_icon.to_s
				if icon_link.eql? ""
					"No Icon"
				elsif not icon_link.include? "http"
					icon_link = "http://kidstrade.com" + icon_link.to_s
					icon_link.gsub(":ImageUploader", "")
					puts "-" * 40
					puts icon_link
					image_tag(icon_link, size:"50x50")
				else
					puts "-" * 40
					puts icon_link
					image_tag(icon_link, size:"50x50")
				end
			end
			row :female_icon do |category|
				icon_link = category.female_icon.to_s
				if icon_link.eql? ""
					"No Icon"
				elsif not icon_link.to_s.include? "http"
					icon_link = "http://kidstrade.com" + icon_link.to_s
					icon_link.gsub(":ImageUploader", "")
					puts "-" * 40
					puts icon_link
					image_tag(icon_link, size:"50x50")	
				else
					puts "-" * 40
					puts icon_link
					image_tag(icon_link, size:"50x50")
				end
			end
		end
	end
end
