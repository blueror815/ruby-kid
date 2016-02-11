

ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base, access_key_id: ENV['AWS_SES_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SES_SECRET_ACCESS_KEY']

ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = 'kidstrade.com'

Mail.register_interceptor(DevelopmentMailInterceptor) if Rails.env.development?  

require 'net/smtp'

module Net
  class SMTP
    def tls?
      false
    end
  end
end