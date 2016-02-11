require 'test_helper'
require 'user_helper'
require 'item_helper'

class BadWordTest < ActiveSupport::TestCase

  include UserHelper
  include ItemHelper

  test "Filter Item" do
    original_texts = []
    bad_words_for_items = [] # correspond to item order

    # 1st item
    item = Item.new( attributes_for(:item_with_category_id) )
    item_1_desc_words = @bad_words_cache[0,3].collect(&:strip_acronymns)
    bad_words_for_items << item_1_desc_words
    item.description << ' ' + item_1_desc_words.join(' ')

    item.user_id = @child.id
    item.save
    photo_attr = attributes_for(:photo_ff13)
    file_data = load_photo_file_data(photo_attr[:image])
    item.load_item_photos_with_params( item_photos: [file_data] )
    original_texts << item.description

    # 2nd item
    second_item = Item.new( attributes_for(:item_with_top_category) )
    item_2_desc_words = @bad_words_cache[3,3].collect(&:strip_acronymns)
    bad_words_for_items << item_2_desc_words
    second_item.description << ' ' + item_2_desc_words.collect(&:upcase).join(' ')
    second_item.user_id = @child.id
    second_item.save
    photo_attr = attributes_for(:photo_ff13)
    file_data = load_photo_file_data(photo_attr[:image])
    second_item.load_item_photos_with_params( item_photos: [file_data] )
    original_texts << second_item.description
    Item.owned_by(@child).order('id asc').each_with_index do|_item, idx|
      _item.activate!
      filters = ::Filters::FilteredRecord.filter(@child.id, _item, ['description'] )
      assert filters.present?
      assert filters.first.matches.present?
      bad_words_for_item = bad_words_for_items[idx]
      puts "-------------- #{bad_words_for_item} -------------------\n  #{filters.first.original_text}"

      # This Obscenity cannot filter out non-alphabets well.
      if bad_words_for_item.none?{|w| w =~ /[^a-z]/i }
        matches = filters.first.matches.split(::Filters::FilteredRecord::MATCHES_WORD_SEPARATOR).collect{|w| w.strip_acronymns.downcase }
        assert matches.present?
        assert bad_words_for_item.collect(&:downcase).all?{|w| matches.include?(w.downcase) }, "Expected matches to include all #{bad_words_for_item}\n#{matches}"
      end
      ::FilterRecordWorker.drain
      puts "VVV --------------\n  #{_item.description}"
      _item.reload
      assert_not_equal _item.description, filters.first.original_text
      assert ::Obscenity.offensive(_item.description).blank?, "Should have not any more offensive words: #{_item.description}"
      assert_equal 'REPORT_SUSPENDED', _item.status

    end
    assert_equal 3, Filters::FilteredRecord.where(user_id: @child.id).count # that bong counts too
    assert Filters::FilteredRecord.where(user_id: @child.id).to_a.all?{|c| c.content_type == 'Item' }

    # Buyer asking question
    @buyer = create(:tiger_child)
    @buyer.reload
    item.item_comments << ItemComment.create(user_id: @buyer.id, recipient_user_id: @child.id, item_id: item.id, buyer_id: @child.id,
      parent_id: @child.id, body: "Some words are bad #{item_1_desc_words.join(' ')}")
    puts "-" * 200
    item.save

    ::FilterRecordWorker.drain
    item.reload
    assert item.item_comments.all?{|c| ::Obscenity.offensive(c.body).blank? }
    assert item.item_comments.all?{|c| c.open? == false }
    assert_equal 1, Filters::FilteredRecord.where(user_id: @buyer.id).count
    assert Filters::FilteredRecord.where(user_id: @buyer.id).to_a.all?{|c| c.content_type == 'ItemComment' }

    # Start on trade
    trade = ::Trading::Trade.new(buyer_id: @buyer.id, seller_id: @child.id)
    trade.save
    trade.add_items_to_trade!(@buyer, [item])

    trade_coment_bad_words = @bad_words_cache[10,5]
    trade_comment = "Trade comments " + trade_coment_bad_words.join(" ")
    puts '38' * 2000
    trade.trade_comments << ::Trading::TradeComment.new(user_id: @buyer.id, comment: trade_comment )
    trade.save

    ::FilterRecordWorker.drain
    trade.reload
    assert assert trade.trade_comments.all?{|c| ::Obscenity.offensive(c.comment).blank? }, "TradeComment should be filterd (origina: #{trade_comment}"
    assert assert trade.trade_comments.all?{|c| c.report_suspended? }
    assert Filters::FilteredRecord.where(user_id: @buyer.id).to_a.any?{|c| c.content_type == 'Trading::TradeComment' && c.content_type_id == trade.trade_comments.first.id }

    puts "========================"
  end

  protected

  def setup
    User.delete_all

    @child = create(:selling_child)
    @child.reload
    @bad_words_cache = ::Filters::BadWord.cache.shuffle
    Filters::FilteredRecord.where(user_id: @child.id).delete_all

  end
end
