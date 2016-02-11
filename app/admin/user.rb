#remove_filter is to get rid of the Broken way that ActiveAdmin handles has_many associations.
# source : https://github.com/activeadmin/activeadmin/issues/2501

ActiveAdmin.register User do
	remove_filter :children
	remove_filter :parents
	remove_filter :friends
	config.filters = false

	index do
		id_column
		column :user_name
		column :email
		actions 
	end

	show do
		attributes_table do
			row :profile_image do |user|
				image_tag("http://kidstrade.com" + user.profile_image.to_s, size:"50x50")
			end
			row :id
			row :user_name
			row :first_name
			row :gender
			row :grade
			row :current_school
			row :birthdate
			row :isParent do
				if user.is_a?(Parent)
					'Yes'
				else
					'No'
				end
			end
			if user.is_a?(Parent)
				row 'Children' do |n|
					user.children.each.map do |child|
						link_to(child.user_name, administrator_user_path(child))
					end.join('<br>').html_safe
				end
			else
				row 'Parent' do |n|
					user.parents.each.map do |parent|
						link_to(parent.user_name, administrator_user_path(parent))
					end.join('<br>').html_safe
				end
			end
		end
		panel "Items" do
			table_for user.items do
				column :thumbnail do |item|
					image_tag(item.default_thumbnail_url, size:"50x50")
				end
				column :title
				column :price
				column :id
				column :link do |item|
					link_to("link to item", administrator_item_path(item)).html_safe
				end
			end
		end

		if user.is_a?(Child)
			trades = ::Trading::Trade.for_user(user.id)
			panel "Trades" do
				table_for trades do
					column 'To Trade Show Page' do |trade_obj|
						link_to("link", administrator_trade_path(trade_obj)).html_safe
					end
					column :buyer
					column :seller
					column :status
				end
			end
		end
	end
end