class AddDefaultThumbnailUrlToItems < ActiveRecord::Migration
  def change
    add_column :items, :default_thumbnail_url, :string, :length => 255
    
  end
end
