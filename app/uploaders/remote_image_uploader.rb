# encoding: utf-8
##

class RemoteImageUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:

  include ::CarrierWave::RMagick
  # include ::CarrierWave::Backgrounder::Delay

  include ::CarrierWaveDirect::Uploader

  include Sprockets::Helpers::RailsHelper
  include Sprockets::Helpers::IsolatedHelper


  MAX_WIDTH = 5000
  MAX_HEIGHT = 5000
  # include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:

  storage :fog

  #require 'carrierwave/processing/mime_types'
  #include CarrierWave::MimeTypes

  def will_include_content_type
    true
  end

  def set_content_type(*args)
    name_match = original_filename.match( /([^\/]+)\.([\w]{2,4})$/ )
    content_type = (name_match) ? ("image/#{$2.downcase}" ) : 'image/jpeg'
    puts "  -> set content type #{content_type} of #{original_filename}"
    self.file.instance_variable_set(:@content_type, 'image/jpeg')
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted.

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:

  process :set_content_type
  process :resize_to_limit => [MAX_WIDTH, MAX_HEIGHT]
  process :store_dimensions


  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  version :thumb do
    #originally 360 x 360 limit
    process :resize_to_limit => [296, 900]
    process :set_content_type
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end


  private


  def store_dimensions
    if file && model && model.respond_to?(:width) && model.respond_to?(:height)
      img = ::Magick::Image::read(file.file).first
      model.width = img.columns
      model.height = img.rows
    end
  end

end
