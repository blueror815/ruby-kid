
module Scrapers
  class Toysrus

    # @return <Hash of attributes title, price, description, images<Array>, specifications<Hash> ]
    def self.export_item_info(page, defaults = {} )
      h = {}
      # pid = uri.to_s.match(/productid=(\d+)/i ).try(:[], 1)
  
      h['title'] = page.title.match(/(.+)\s*\-\s*Toys\s+["]?R["]?\s+us/i).try(:[], 1)
      h['price'] = page.parser.xpath("//div[@id='price']").text.match(/\$\s*(\d+(\.\d{2})?)/).try(:[], 1).to_f
      h['description'] = page.parser.xpath("//div[@id='prod_desc_1']").inner_html +
          page.parser.xpath("//div[@id='Description']/p").inner_html
      
      # Categories, try to match from deepest level first
      category = nil
      page.links_with(class: 'breadcrumb').reverse.find do|bc|
        category = Category.search { fulltext bc.text.strip }.results.first
        category
      end
      category ||= Category.find_by_id(defaults[:category_id] ) if defaults[:category_id]
      category ||= Category.where(level: 1).first
      h['category_id'] = category.id
  
      specs = {}
      page.parser.xpath("//div[@id='AddnInfo']//p").collect do |p|
        next if p.text.blank?
        match = p.text.match(/(.+):\s*(.+)/)
        specs[match[1]] = match[2] if match
      end
      h['specifications'] = specs if specs.size > 0
  
      h['images'] = page.images_with(:src => /\/graphics\/product_images\/.+dt\.jpe?g/i).collect { |img| URI.join(page.uri, img.src).to_s }
  
      h
    end
  
    def self.export_item_page_urls(page)
      page.links_with(class: 'prodtitle', href: /product\/index(.jsp)?\?/i).collect { |link| URI.join(page.uri, link.href).to_s }
    end
    
    ##
    # Arguments:
    #   page <Mechanize::Page> expected to be a page with all categories, such as http://www.toysrus.com/category/index.jsp?categoryId=2273442&ab=TRU_Header:Utility3:See-All-Categories:Home-Page
    
    def self.import_categories!(page)
      page.parser.xpath("//div[contains(@class,'subCatBlockTRU')]").each do|subblock|
        headers = subblock.xpath('.//h2')
        next if headers.empty? || headers.any?{|header| header.text =~ /back to school|top rated|great deals store|clearance|what's new/i }
        subcat = Category.new(name: headers.first.text.strip, level: 1)
        puts subcat.name
        children_cats = []
        subblock.xpath(".//ul/li//a").each_with_index do|c,child_index| 
          new_child =  Category.new(name: c.text.strip, level: 2, level_order:child_index); 
          puts '  ' + new_child.name
          children_cats << new_child;
        end
        subcat.subcategories = children_cats
        subcat.save
      end
    end
    
    ##
    # Browse for items and create actual items and activate for the user
    # @options <Hash>
    #   :saving => (boolean) Default true; Whether actually saves and activates items after info gather.  If false, brief output is displayed and block yield.
    #   :default_category_id => If 
    
    def self.import_items_from_page_to_user!( page, user, options = {} )
      saving = options[:saving].nil? ? true : options[:saving]
      default_category_id = options[:default_category_id]
      items = []
      
      urls_set = Set.new
      page.links_with(:href => /\/product\/index.jsp\?.*productId=\d+/i ).each do|link|
        next if urls_set.include?(link.href)
        begin
          item_page = link.click
          item_info = export_item_info(item_page, { category_id: default_category_id} )
          item = Item.new(title: item_info['title'].to_s.toutf8, price: item_info['price'], description: item_info['description'].to_s.toutf8,
            category_id: item_info['category_id'] )
          item.user_id = user.id
          item.item_photos = item_info['images'].collect{|img| ItemPhoto.new(remote_image_url: img) }
          if saving
            item.save
            item.activate!
          else
            puts "%25s | $7.2f | %3i | in %15s" % [item.title, item.price, item.quantity, Category.find(item_info['category_id']).name ]
            yield item
          end
          items << item
          urls_set << link.href
        rescue Exception => item_e
          puts "** ERROR: #{item_e.message}"
        end
      end
      items
    end

  end
end
