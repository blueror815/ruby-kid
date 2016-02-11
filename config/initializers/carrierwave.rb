CarrierWave.configure do|config|
  config.fog_credentials = {
    provider: 'AWS',
    aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
    aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  }
  config.fog_directory = ENV['AWS_S3_BUCKET']
  config.fog_public = true

  config.will_include_content_type = true

  config.default_content_type = 'image/jpg'
  config.allowed_content_types = %w(image/jpg image/jpeg image/gif image/png)
end