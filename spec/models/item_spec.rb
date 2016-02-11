require 'rails_helper'
require 'spec_helper'
require Rails.root.join('test', 'user_helper')

#copy and pasted the rspec stuff from https://github.com/sunspot/sunspot/wiki/RSpec-and-Sunspot
$original_sunspot_session = Sunspot.session
Sunspot.session = Sunspot::Rails::StubSessionProxy.new($original_sunspot_session)

RSpec.configure do |c|
  c.include UserHelper
end

RSpec.describe Item do
    context "Item Category" do
        before(:all) do
            unless $sunspot
          $sunspot = Sunspot::Rails::Server.new
          pid = fork do
            STDERR.reopen('/dev/null')
            STDOUT.reopen('/dev/null')
            $sunspot.run
          end
          # shut down the Solr server
          at_exit { Process.kill('TERM', pid) }
          # wait for solr to start
          sleep 5
        end
        Sunspot.session = $original_sunspot_session
        end

        after(:all) do
            Item.remove_all_from_index!
        end

        before(:each) do
            @action_figure_cat_keyword = create(:cat_keyword)
            @item = build(:lego_train_set)

            parent, user = create_parent_and_child(:selling_parent, :selling_child)
            @item.user = user
            @item.activate!
            
            @item.save
            Item.remove_all_from_index!
            # since Sidekiq isn't called within a testing environment, then the method to create associations isn't called. All other after_save
            #callback still run.
        end

        it "should create associated category when the description contains a category keyword" do
            #create item and everything
            associations = @item.associated_categories
            expect(associations.empty?).to be_truthy
            Item.check_desc_for_associations!(@item.description, @item.category_id, @item.id)
            @item.reload
            expect(@item.associated_categories.length).to eq(1)
            expect(@item.associated_categories.first.category_id).to eq(@action_figure_cat_keyword.category_id)
        end

        it "shouldn't create an association when the description doesn't include the keyword" do
            @item.description = "not keyword"
            @item.save
            @item.reload
            Item.check_desc_for_associations!(@item.description, @item.category_id, @item.id)
            @item.reload
            expect(@item.associated_categories.length).to eq(0)
        end

        it "should create an association if the description includes an uppercase version of the keyword" do
            #category keyword is 'action figure'
            @item.description = 'ACTION FIGURE IS INCLUDED IN THE PACKAGE'
            @item.save
            @item.reload
            Item.check_desc_for_associations!(@item.description, @item.category_id, @item.id)
            @item.reload
            expect(@item.associated_categories.length).to eq(1)
            expect(@item.associated_categories.first.category_id).to eq(@action_figure_cat_keyword.category_id)
        end

        it "shouldn't create an association if the category equals the would be association" do
            @item.category_id = 10000
            @item.save
            @item.reload
            Item.check_desc_for_associations!(@item.description, @item.category_id, @item.id)
            @item.reload
            expect(@item.associated_categories.length).to eq(0)
        end

        it "should return items that are associated with a category" do
            #the category keyword has a category id of 10000 (equal to params)
            #so the search will only return the @item object if it's associated correctly
            @item.category_id = 0
            @item.description = 'action figure'
            @item.save
            @item.reload
            Item.check_desc_for_associations!(@item.description, @item.category_id, @item.id)
            @item.index!
            params = {
                :category_id => 10000
            }

            search = Item.build_search(params)
            search.execute
            expect(search.results.collect(&:id)).to include(@item.id)
        end

        it "should search through more than one associated category for an item" do
            @new_cat_keyword = build(:cat_keyword)
            #Changing the keyword so it makes an associated category for "Dolls"
            @new_cat_keyword.category_id = 20000
            @new_cat_keyword.keyword = 'figure'
            @new_cat_keyword.save
            Item.check_desc_for_associations!(@item.description, @item.category_id, @item.id)
            @item.reload
            @item.index!
            
            #it should have two associated categories now
            expect(@item.associated_categories.length).to eq(2)

            #create search
            params = {
                :category_id => 20000
            }

            search = Item.build_search(params)
            search.execute
            expect(search.results.collect(&:id)).to include(@item.id)
        end
    end
end
