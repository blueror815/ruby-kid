ActiveAdmin.register ::Trading::Trade, as: "Trades" do
	config.filters = false
	index do
		id_column
		column :buyer
		column :seller
		column :status
	end

	show do
		panel "Items" do
			table_for trades.trade_items do	
				column :image do |trade_item|
					item = Item.where(id: trade_item.item_id).first
					image_tag(item.default_thumbnail_url, size:"50x50")
				end
				column 'Picked by' do |trade_item|
					trade = ::Trading::Trade.where(id: trade_item.trade_id).first
					if trade_item.seller_id.eql? trade.seller_id
						'Buyer'
					else
						'Seller'
					end
				end
				column :owner do |trade_item|
					user = trade_item.seller
					link_to(user.user_name, administrator_user_path(user)).html_safe
				end
				column :title do |trade_item|
					item = Item.where(id: trade_item.item_id).first
					link_to(item.title, administrator_item_path(id: item.id)).html_safe
				end
				column :price do |trade_item|
					item = Item.where(id: trade_item.item_id).first
					item.price
				end
				column :quantity
			end
		end


		attributes_table do
			row :id
			row :buyer
			row :seller
			row :status
		end
	end
end