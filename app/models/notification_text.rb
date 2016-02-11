##
#
class NotificationText < ActiveRecord::Base

	attr_accessible :identifier, :title, :subtitle, :push_notification, :language, :non_tech_description,
                  :title_for_item, :subtitle_for_item, :title_for_trade, :subtitle_for_trade, :title_for_parent, :tip_for_parent,
									:title_for_trade_b, :tip_for_trade_b, :title_for_item_b, :tip_for_item_b, :created_at, :updated_at

  cache_records :store => :shared, :key => 'notification_text'

  @@cache = {} # { '%{language}' => {'%{copy_identifier}' => Array of %{NotificationText#id} } }

  ##
  # Just like the old Notifcation @@cache, but in more appropriate model class.
  # Any change to NotificationText record would be handled by cache_record.
  # @return <NotificationText selected>
  def self.get_cache(copy_identifier, language = 'en')
    language_h = @@cache[language] || nil
    if language_h.nil?
      language_h = {}
      @@cache[language] = language_h
    end
    result_list = language_h[copy_identifier]
    result_id = 0
    if result_list.nil?
      result_list = where(language: language, identifier: copy_identifier).all.collect(&:id)
      result_id = result_list.empty? ? 0 : result_list.shuffle.first
      logger.info "|:: #{self} for #{copy_identifier}: #{result_list} => #{result_id}"
      language_h[copy_identifier] = result_list
    else
      result_id = result_list.empty? ? 0 : result_list.shuffle.first
    end
    result_id == 0 ? nil : where(id: result_id).first
  end

  def self.populate_from_data_file
    ActiveRecord::Base.establish_connection
    conn = ActiveRecord::Base.connection
    file_path = Rails.root.join('doc', 'data', 'notification_texts.sql')
    body = File.read(file_path)
    body.split(';').each do|statement|
      if /^\s*\w+/ =~ statement
        conn.execute(statement)
      end
    end
    @@cache.clear
    puts "|- Loaded #{NotificationText.count} notification_texts"
  end

  def self.populate_from_yaml_file
    h = YAML::load_file( File.join(Rails.root, 'doc/data/notification_texts.yml') )
    list = h.is_a?(Array) ? h : h.values.first
    list.each do |yml_record|
      record = where(identifier: yml_record.identifier, title: yml_record.attributes['title'] ).first || new
      record.attributes = yml_record.attributes.select{|attr| attr.to_s != 'id' }
      puts "#{record.new_record? ? '+' : '*'} %16s | %24s | %30s" % [record.identifier, record.title, record.subtitle] if Rails.env.development?
      record.save
    end
    @@cache.clear
    puts "|- Loaded #{NotificationText.count} notification_texts"
  end

  def self.export_to_yaml_file(file_path = nil)
    file_path ||= File.join(Rails.root, 'doc/data/notification_texts.yml')
    File.open(file_path, 'w+') {|f| f << NotificationText.all.to_yaml }
  end
end
