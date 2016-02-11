class BackgroundLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    "#{msg}\n"
  end
end
 
logfile = File.open(File.join(Rails.root, '/log/background.log'), 'a')  #create log file
logfile.sync = true  #automatically flushes data to file
BG_LOGGER = BackgroundLogger.new(logfile)  #constant accessible anywhere