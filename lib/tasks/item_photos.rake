task :copy_item_photos => :environment do
  puts "#############################"
  puts "# Copy Item Photos of #{Item.count} items"
  puts Time.now.to_s(:db)

  #conn = ::Fog::Connection.aws_connection
  #basedir = conn.base_directory

  Item.all.each do|item|
    next if item.item_photos.blank?
    puts "Item #{item.id} - #{item.item_photos.count}"
    item.item_photos.each do|photo|

      # Old version was actually file storage, so this URL generated from fog storage is wrong.
      image_url = photo.image_url
      file_name = image_url.match(/\/([^\/]+)$/ )[1]
      file_path = File.join(Rails.root, 'public', photo.image.store_dir, file_name)
      begin
        File.open(file_path) do|f|
          photo.image = f
          photo.key = file_name
          photo.url = nil
          photo.save
        end

      rescue Errno::ENOENT
        puts " ** Cannot find photo #{file_path}"
        #photo.destroy
      rescue Exception => error
        puts " ** Error: #{error}\n#{error.backtrace.join("  \n") }"
      end
    end

  end # each item
end