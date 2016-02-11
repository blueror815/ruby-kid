ActiveAdmin.register ::Trading::TradeItem, as: 'TradeItem' do
	belongs_to :trades
	belongs_to :item
end
