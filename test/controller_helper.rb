##
# Intended for use for integration tests.  Inside functional tests, the scope of controller still would cause
# problem using these named route like user_session_path within scope other than '/users'

module ControllerHelper
  def login_with(user_name, password, format = nil)
    get new_user_session_path
    post_via_redirect user_session_path(format: format), user: {login: user_name, password: password}
    assert_response :success
    #puts "--------> Attempted login #{user_name} | #{password}"
  end
  
  def logout
    delete destroy_user_session_path
  end
  
  def assert_alert_message(source, message)
    doc = Nokogiri::HTML.parse(source)
    msg_panel = doc.xpath("//div[@id='message-panel']")
    assert_not_nil msg_panel, "Page should include a message-panel"
    assert_not_nil msg_panel.inner_text.match( /#{message.gsub(/(\s+)/, '\s+')}/i ), "Should include the message: #{message}"
  end

  ##
  # SOLR servers

  def setup
    check_solr
    check_notification_texts
  end

  def check_solr
    #puts " .. Check SOLR test ..............................."
    pid_dir =  File.join(Rails.root, "solr/pids/#{Rails.env}")
    pid_file = Dir.entries(pid_dir).find{|fn| fn =~ /\.pid$/ }
    process_id = nil
    begin
      if pid_file 
        process_id = Process.getpgid( File.open(File.join(pid_dir, pid_file) ).read.to_i )
      end
    rescue Exception => e
      puts "  ** Error #{e}"
    end
    
    if process_id.nil?
      #puts "  \\.. starting SOLR"  
      Sunspot::Rails::Server.new.start
    end
  rescue Sunspot::Solr::Server::AlreadyRunningError
    #puts "   \\.. already running"
  end

  def check_notification_texts
    if NotificationText.count == 0
      NotificationText.populate_from_data_file
      #puts "\\.. preloaded with #{NotificationText.count} notification_texts"
    end
  end

=begin 
  def teardown
    puts " .. stopping SOLR test"
    Sunspot::Rails::Server.new.stop
  rescue Exception => e
    puts "** Error in shutting down SOLR: #{e.message}"
  end
=end
end