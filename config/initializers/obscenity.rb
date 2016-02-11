Obscenity.configure do |config|
  config.blacklist   = "config/bad_words.yml"
  config.whitelist   = ["safe", "word"]
  config.replacement = :stars
end