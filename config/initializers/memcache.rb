
memcache_options = {
    :c_threshold => 10_000,
    :compression => true,
    :debug => false,
    :namespace => '_Webiva',
    :readonly => false,
    :urlencode => false
  }



require 'memcache'

memcache_servers = [ 'localhost:11211' ]
CACHE = MemCache.new memcache_options
CACHE.servers =  memcache_servers


# Workling::Remote.dispatcher = Workling::Remote::Runners::StarlingRunner.new
Workling::Remote.dispatcher = Workling::Remote::Runners::StarlingRunner.new
Workling::Return::Store::Base # Load the base module first
Workling::Return::Store.instance = CACHE

Webiva::Application.configure do
#  config.cache_store = :mem_cache_store, memcache_servers, memcache_options
#  config.session_store :mem_cache_store, :cache => CACHE, :key => '_Webiva'
end
