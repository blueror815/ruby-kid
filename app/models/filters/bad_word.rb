module Filters
  class BadWord

    @@BAD_WORDS = nil

    def self.cache
      if @@BAD_WORDS.nil?
        reload_from_data_file
      end
      @@BAD_WORDS
    end

    def self.reload_from_data_file
      @@BAD_WORDS = []
      file_path = Rails.root.join('doc', 'data', 'bad_words.txt')
      f = File.new(file_path)
      f.each {|line| next if line.blank?; @@BAD_WORDS << line.strip.downcase }
      puts "|- Loaded #{@@BAD_WORDS.count} from #{file_path}"
      @@BAD_WORDS
    end
  end
end