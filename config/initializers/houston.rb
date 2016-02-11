require 'houston'

#environment variables are automatically read from whatever is used to start the server

if Rails.env.production?
	APN = Houston::Client.production
	APN.certificate = File.read(Rails.root.join('config/certificates/CubbyShop-Production-APNS-Certificates.pem'))
else
	APN = Houston::Client.development
	APN.certificate = File.read(Rails.root.join('config/certificates/CubbyShop-Push-Dev-Certificates.pem'))
end