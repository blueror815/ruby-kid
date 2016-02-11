##
# @url being temporary source of remote image, such as one from AWS S3, that will later be processed into actual image.

class ItemPhoto < ActiveRecord::Base
  attr_accessible :item_id, :name, :image, :default_photo, :width, :height, :metadata, :url, :image_processing
  
  belongs_to :item
  
  if Rails.env.test?
    mount_uploader :image, ::ImageUploader
  else
    mount_uploader :image, ::RemoteImageUploader
  end
  MAX_ITEM_PHOTOS = 4
  
  before_save :set_image_data
  after_save :set_info_to_item!
  after_commit :enqueue_image
  after_destroy :cleanup_image

  ##
  # Sets the width & height of image
  def set_image_data
    #logger.info " --- dimensions now #{self.width}, #{self.height} w/ url #{self.url}"
    #puts " --- dimensions now #{self.width}, #{self.height} w/ url #{self.url}"
  end
  
  def set_info_to_item!
    url = self.image_url(:thumb)

    if url.present?
      if (item.default_thumbnail_url.blank? || self.default_photo? )
        item.update_attribute(:default_thumbnail_url, url )
      end
    end

  end

  def enqueue_image
    if not image_processing? && self.image.nil?
      puts "  + set async image worker #{id}, key #{key}"
      self.update_column(:image_processing, true)
      ImageWorker.perform_async(id, key) if key.present?
    end
  end
  
  def cleanup_image
    if self.image
      self.remove_image!
    end
  rescue Exception
  end


  def as_json(options = nil)
    { url: url.present? ? url : image_url, width: width.to_i, height: height.to_i }
  end
  
  # In future, additional conditions or rules may be applied such as premium privilleges.
  
  def self.over_the_limit?(item)
    item.item_photos.count > MAX_ITEM_PHOTOS
  end
  
  # @return might be nil
  def self.select_default_item_photo_for(item)
    item.item_photos.present? ?
      (item.item_photos.find(&:default_photo) || item.item_photos.order('id asc').first) : nil
  end
  
  # @return might be nil
  def self.default_thumbnail_url_for(item)
    photo = select_default_item_photo_for(item)
    photo ? photo.image_url(:thumb) : nil
  end

  class ImageWorker
    include Sidekiq::Worker

    def perform(id, key)
      photo = ItemPhoto.find(id)
      puts "| Given id #{id}, key #{key}, url #{photo.url}"

      if photo.image_processing? && photo.image_url.blank?
        photo.key = key
        photo.remote_image_url = photo.url || photo.image.direct_fog_url(with_path: true)
        photo.url = nil
        photo.save!
        puts "  ... processing (#{id}) photo #{photo.remote_image_url}"

      else
        puts "  ... photo(#{id}) processing? #{photo.image_processing?}, w/ image #{photo.image_url}"
      end
      photo.update_column(:image_processing, false)

    rescue ActiveRecord::RecordNotFound
      puts "** ? Cannot find photo #{id} vs last photo #{ItemPhoto.last.id}"
    end
  end

end
