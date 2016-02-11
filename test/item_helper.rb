module ItemHelper

  def load_photo_file_data(file_path, mime_type = 'image/jpg')
    Rack::Test::UploadedFile.new(file_path)
  end
end