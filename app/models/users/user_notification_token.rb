module Users
	class UserNotificationToken < ActiveRecord::Base

		self.table_name = 'user_notification_tokens'
		#constant for checking platform_type of user_notification rows
		IOS = 'ios'
		ANDROID = 'android'

		IOS_NOTIFICATION_SOUND = 'apns.caf'

		#iffy on this should be attr_accessible
		attr_accessible :platform_type, :user_id, :token, :created_at

		belongs_to :user

		object_constants :platform_type, :ios, :android

		validates_presence_of :token, :platform_type

		##
		# Batch delivery of text to user's all devcies
		def self.send_push_notifications_to(user_or_user_id, notification_text, extra_params = {})
			user = user_or_user_id.is_a?(::User) ? user_or_user_id : User.find_by_id(user_or_user_id)
			return if user.nil?
			devices = where(user_id: user.id).all
			if devices.blank? && user.is_a?(::Child) && user.parent
				devices = where(user_id: user.parent_id).all
			end
			devices.each do |device|
				logger.info "-> Push Note to #{user.user_name}, #{device.platform_type}\n| #{notification_text}\n#{extra_params}"
				case device.platform_type
					when IOS
						send_ios_push_notification(notification_text, device.token, extra_params)
					when ANDROID
						send_android_push_notification(notification_text, device.token, extra_params)
				end
			end
		end

		def self.send_android_push_notification(notification_text, token, extra_params = {})
			note = Rpush::Gcm::Notification.new
			note.app = Rpush::Gcm::App.find_by_name("KidsTrade_android")
			note.registration_ids = [token]
			note.data = {message: notification_text}
			note.save!
		end

		def self.send_ios_push_notification(notification_text, token, extra_params = {})
			#using houston to send IOS notification
			# notification = Houston::Notification.new(device: token)
			# notification.alert = notification_text
			# notification.sound = extra_params[:sound] || IOS_NOTIFICATION_SOUND

			# notification.badge = extra_params[:badge] if extra_params[:badge]
			# notification.custom_data = extra_params[:custom_data]
			# #the server hangs if the token isn't correct, so uncomment this when the token is valid.
			# APN.push(notification)
			if Rails.env.production?
		        pusher = Grocer.pusher(
		            # certificate: File.read(Rails.root.join('config/certificates/CubbyShop-Production-APNS-Certificates.pem')),
		            certificate: File.join(Rails.root, 'config/certificates', 'CubbyShop-Production-APNS-Certificates.pem'),
		            passphrase: "",
		            gateway: "gateway.push.apple.com",
		            port: 2195,
		            retires: 3
		        )   
	      	else
		        pusher = Grocer.pusher(
		            # certificate: File.read(Rails.root.join('config/certificates/CubbyShop-Push-Dev-Certificates.pem')),
		            certificate: File.join(Rails.root, 'config/certificates', 'CubbyShop-Push-Dev-Certificates.pem'),
		            passphrase: "",
		            gateway: "gateway.sandbox.push.apple.com",
		            port: 2195,
		            retires: 3
		        )
	      	end

	      	notification = Grocer::Notification.new(device_token: token)
	      	notification.alert = notification_text
	      	notification.sound = extra_params[:sound] || IOS_NOTIFICATION_SOUND
	      	notification.badge = extra_params[:badge] if extra_params[:badge]
	      	notification.custom = extra_params[:custom_data]

	      	pusher.push(notification)

		end
	end
end
