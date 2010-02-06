
memcache_options = {
    :c_threshold => 10_000,
    :compression => true,
    :debug => false,
    :namespace => 'Webiva',
    :readonly => false,
    :urlencode => false
  }



require 'memcache'


CACHE = MemCache.new memcache_options

CACHE.servers =  [ 'localhost:11211' ]
ActionController::Base.session_options[:cache] = CACHE


# Workling::Remote.dispatcher = Workling::Remote::Runners::StarlingRunner.new
Workling::Remote.dispatcher = Workling::Remote::Runners::StarlingRunner.new
Workling::Return::Store::Base # Load the base module first
Workling::Return::Store.instance = CACHE

