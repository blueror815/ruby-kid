# --- Version Store
# All Workers that use the Record Cache should point to the same Version Store
# E.g. a MemCached cluster or a Redis Store (defaults to Rails.cache)
RecordCache::Base.version_store = Rails.cache

# --- Record Stores
# Register Cache Stores for the Records themselves
# Note: A different Cache Store could be used per Model, but in most configurations the following 2 stores will suffice:

# The :local store is used to keep records in Worker memory
RecordCache::Base.register_store(:local, ActiveSupport::Cache.lookup_store(:memory_store))

# The :shared store is used to share Records between multiple Workers
RecordCache::Base.register_store(:shared, Rails.cache)

# Different logger
# RecordCache::Base.logger = Logger.new(STDOUT)
