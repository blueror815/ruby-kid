module Fog
  class Connection

    ##
    # @return <Fog::Storage>
    def self.aws_connection
      Fog::Storage.new(provider: 'AWS',
                       aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                       aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
    end


    ##
    # @return <Fog::Storage::AWS::Directory>
    def self.get_base_directory(fog_connection)
      fog_connection.directories.get(ENV['AWS_S3_BUCKET'])
    end

    ## The subdirectory path inside buc
    # @file_url <String> Example: https://s3.amazonaws.com/cubbyshop-uploads/test/hello_kitty_shoe.jpg
    # @return <String>

    AWS_S3_URL_REGEX = /(amazonaws|amazon)\.com\/([\w\-_\.]+)((\/[\w\-\._]+)+)$/

    ##
    # Break up of the file_url to only get sub-path after base directory
    def self.get_sub_path_from_url(file_url)
      if AWS_S3_URL_REGEX =~ file_url
        $3
      else
        nil
      end
    end

    # @return Fog::Storage::AWS::File
    def self.get_file_from_url(directory, file_url)
      path = get_sub_path_from_url(file_url)
      path_parts = path.split('/')
      path_only = path.gsub(path_parts.last, '')
      directory.files.get(path_parts.last, prefix: path_only)
    end

  end
end

module Fog
  module Storage
    class AWS
      class Real

        def base_directory
          ::Fog::Connection.get_base_directory(self)
        end

        def get_file_from_url(directory, file_url)
          ::Fog::Connection.get_file_from_url(directory, file_url)
        end

      end
    end
  end
end