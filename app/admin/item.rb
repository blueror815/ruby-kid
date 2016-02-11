ActiveAdmin.register Item do
	belongs_to :user, optional: true
	navigation_menu :default
	filter :price
	filter :description

	index do
		column :user, as: 'Owner'
		column :default_thumbnail do |item|
			image_tag(item.default_thumbnail_url, size:"50x50")
		end
		column :description
		column :price do |item|
			#%.2f is ruby's version of a NumberForatter from Java
			price_to_return = "$" + ('%.2f' % item.price).to_s
			price_to_return
		end
		column :intended_age_group
		actions
	end

	show do
		attributes_table do
			row :id
			row :user, as: 'Owner'
			row :title
			row :description
			row :price do |item|
				price_to_return = "$" + ('%.2f' % item.price).to_s
				price_to_return
			end
			#going to leave this as is, since the links for all the pictures not on the AWS servers aren't valid links.
			row :default_thumbnail_url do |item|
				image_tag(item.default_thumbnail_url)
			end
			row :active_trade do |item|
				trade = item.trades.first
				unless trade.nil? # if this passes we know tha thte item is currently involved in a trade
					link_to("Current Trade", administrator_trade_path(trade))
				else
					"No active trades"
				end
			end
		end

		panel "Item Photos" do
			photos = item.item_photos
			table_for photos do
				column :name
				column :image do |photo|
					image_tag(photo.url)
				end
				column :URL do |photo| 
					link_to("URL", photo.image.to_s)
				end
			end
		end
	end
end
