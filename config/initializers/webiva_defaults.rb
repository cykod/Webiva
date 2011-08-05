require 'webiva/rails/routes'

Webiva::Application.configure do
  config.webiva_defaults = YAML.load_file("#{Rails.root}/config/defaults.yml")
  config.webiva_defaults['default_language'] ||= 'en'
  config.webiva_defaults['default_country'] ||= 'US'
  config.webiva_defaults['active_cache'] ||= true
  config.webiva_defaults['default_datetime_format'] ||= "%m/%d/%Y %I:%M %p"
  config.webiva_defaults['default_date_format'] ||= "%m/%d/%Y"
  config.webiva_defaults['enable_beta_code'] ||= false
  config.webiva_defaults['time_zone'] ||= 'Eastern Time (US & Canada)'
  config.webiva_defaults['editor_login'] ||= false
  config.webiva_defaults['use_x_send_file'] ||= false
  config.webiva_defaults['git_repository'] ||= 'git://github.com/cykod/'
  config.time_zone = config.webiva_defaults['time_zone']
end

# TODO: Need to get rid of these constants
CMS_DEFAULTS = Webiva::Application.config.webiva_defaults

WEBIVA_LOGO_FILE = Webiva::Application.config.webiva_defaults['logo_override']
CMS_DEFAULT_LANGUAGE = Webiva::Application.config.webiva_defaults['default_language']
CMS_DEFAULT_CONTRY = Webiva::Application.config.webiva_defaults['default_country']
CMS_CACHE_ACTIVE = Webiva::Application.config.webiva_defaults['active_cache']
CMS_DEFAULT_DOMAIN = Webiva::Application.config.webiva_defaults['domain']
CMS_SYSTEM_ADMIN_EMAIL = Webiva::Application.config.webiva_defaults['system_admin']
CMS_EDITOR_LOGIN_SUPPORT = Webiva::Application.config.webiva_defaults['editor_login']
DEFAULT_DATETIME_FORMAT = Webiva::Application.config.webiva_defaults['default_datetime_format']
DEFAULT_DATE_FORMAT = Webiva::Application.config.webiva_defaults['default_date_format']
BETA_CODE = Webiva::Application.config.webiva_defaults['enable_beta_code']
GIT_REPOSITORY = Webiva::Application.config.webiva_defaults['git_repository']
CMS_DEFAULT_TIME_ZONE = Webiva::Application.config.webiva_defaults['time_zone']

# Only use X_SEND_FILE if it's enabled and we're not in test mode
USE_X_SEND_FILE = (Rails.env == 'test' || Rails.env == 'cucumber' || Rails.env == 'selenium') ? false : Webiva::Application.config.webiva_defaults['use_x_send_file']

memcache_options = {
    :c_threshold => 10_000,
    :compression => true,
    :debug => false,
    :namespace => 'Webiva',
    :readonly => false,
    :urlencode => false
  }



require 'memcache'

memcache_servers = CMS_DEFAULTS['memcache_servers'] || ['localhost:11211']
CACHE = MemCache.new memcache_options
CACHE.servers =  memcache_servers


# Workling::Remote.dispatcher = Workling::Remote::Runners::StarlingRunner.new
Workling::Remote.dispatcher = Workling::Remote::Runners::StarlingRunner.new
Workling::Return::Store::Base # Load the base module first
Workling::Return::Store.instance = CACHE

Webiva::Application.configure do
  config.cache_store = :mem_cache_store, memcache_servers, memcache_options
  
  # look in ActionDispatch::Session::MemCacheStore, for details about the options
  config.session_store :mem_cache_store, :cache => CACHE, :key => '_session_id', :expire_after => 4.hours
end
