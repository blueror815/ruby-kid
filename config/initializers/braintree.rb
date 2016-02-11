
if Rails.env.development? || Rails.env.staging? || Rails.env.test?
	Braintree::Configuration.environment = :sandbox
	Braintree::Configuration.merchant_id = 'rc6h6np6hwgcxghh'
	Braintree::Configuration.public_key = 'dnd4pgybn4sxrv2x'
	Braintree::Configuration.private_key = '424fb36e69804fd5a2b0cf6706a11490'
else
	Braintree::Configuration.environment = :production
	Braintree::Configuration.merchant_id = ENV["BRAINTREE_MERCHANT_ID"]
	Braintree::Configuration.public_key = ENV["BRAINTREE_PUBLIC_KEY"]
	Braintree::Configuration.private_key = ENV["BRAINTREE_PRIVATE_KEY"]
end
