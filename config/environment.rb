
$KCODE='u'

AUTHORIZATION_MIXIN = "object roles"
DEFAULT_REDIRECTION_HASH = { :controller => '/manage/access', :action => 'denied' }

# Be sure to restart your web server when you modify this file.


# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
ENV['RAILS_ENV'] ||= 'production' 
ENV['HOME'] ||= '/home/webiva'


# Specifies gem version of Rails to use when vendor/rails is not present
# RAILS_GEM_VERSION = '2.3.4'


require 'yaml'

# Set up some constants
  defaults_config_file = YAML.load_file(File.join(File.dirname(__FILE__), "defaults.yml"))
  
  CMS_DEFAULTS = defaults_config_file

  WEBIVA_LOGO_FILE = defaults_config_file['logo_override'] || nil 

  CMS_DEFAULT_LANGUAGE = defaults_config_file['default_language'] || 'en'
  CMS_DEFAULT_CONTRY = defaults_config_file['default_country'] || 'US'
  CMS_CACHE_ACTIVE = defaults_config_file['active_cache'] || true
  CMS_DEFAULT_DOMAIN = defaults_config_file['domain']
  
  CMS_SYSTEM_ADMIN_EMAIL = defaults_config_file['system_admin']

   CMS_EDITOR_LOGIN_SUPPORT = defaults_config_file['editor_login'] || false
  
  DEFAULT_DATETIME_FORMAT = defaults_config_file['default_datetime_format'] || "%m/%d/%Y %I:%M %p"
  DEFAULT_DATE_FORMAT = defaults_config_file['default_date_format'] || "%m/%d/%Y"
  
  BETA_CODE = defaults_config_file['enable_beta_code'] || false
  

 
  GIT_REPOSITORY = defaults_config_file['git_repository'] || nil 

  CMS_DEFAULT_TIME_ZONE = defaults_config_file['time_zone'] || 'Eastern Time (US & Canada)'

#RAILS_ROOT = File.dirname(__FILE__) + "../" unless defined?(RAILS_ROOT)

require File.join(File.dirname(__FILE__), 'boot')


class Rails::Plugin

  def webiva_remove_load_paths(file)
    dir =  File.dirname(file)
    begin
      load_paths.each do |path|
        ActiveSupport::Dependencies.load_once_paths.delete(path) if  path.include?(dir)
      end
    rescue Exception => e
      load_paths.each do |path|
        Dependencies.load_once_paths.delete(path) if  path.include?(dir)
      end
    end

  end

end

Rails::Initializer.run do |config|


  config.database_configuration_file = "#{RAILS_ROOT}/config/cms.yml"
  config.action_controller.session_store = :mem_cache_store
  config.plugin_paths = ["#{RAILS_ROOT}/vendor/plugins", "#{RAILS_ROOT}/vendor/modules" ]
  
  config.time_zone = CMS_DEFAULT_TIME_ZONE
  
 #config.load_paths += Dir["#{RAILS_ROOT}/vendor/gems/**"].map do |dir| 
 #  File.directory?(lib = "#{dir}/lib") ? lib : dir
 #end
  
  config.gem 'mysql'
  config.gem 'mime-types', :lib => 'mime/types'
  config.gem 'radius'
  config.gem 'RedCloth', :lib => 'redcloth'
  config.gem 'BlueCloth', :lib => 'bluecloth'
  config.gem 'gruff'
  config.gem 'slave'
  config.gem 'hpricot'
  config.gem 'daemons'
  config.gem 'maruku'
  config.gem 'net-ssh', :lib => 'net/ssh'
  config.gem 'rmagick', :lib => 'RMagick'
  config.gem 'libxml-ruby', :lib => 'xml'
  config.gem 'soap4r', :lib => 'soap/soap'
  config.gem "json"



  if CMS_CACHE_ACTIVE
    config.gem 'memcache-client', :lib => 'memcache'
  end
  
end

# Only use X_SEND_FILE if it's enabled and we're not in test mode
USE_X_SEND_FILE =  (RAILS_ENV == 'test' || RAILS_ENV == 'cucumber' || RAILS_ENV == 'selenium') ? false : (defaults_config_file['use_x_send_file'] || false)

 memcache_options = {
    :c_threshold => 10_000,
    :compression => true,
    :debug => false,
    :namespace => 'Webiva',
    :readonly => false,
    :urlencode => false
  }

CACHE = MemCache.new memcache_options

# Workling::Remote.dispatcher = Workling::Remote::Runners::StarlingRunner.new
Workling::Remote.dispatcher = Workling::Remote::Runners::StarlingRunner.new
Workling::Return::Store::Base # Load the base module first
Workling::Return::Store.instance = CACHE
if RAILS_ENV == 'production'
  Workling::Base.logger = ActiveSupport::BufferedLogger.new(File.dirname(__FILE__) + "/../log/workling_#{RAILS_ENV}.log", ActiveSupport::BufferedLogger::INFO)
else
  Workling::Base.logger = DevelopmentLogger.new(File.dirname(__FILE__) + "/../log/workling_#{RAILS_ENV}.log", 0, 0)
end

ActionMailer::Base.logger = nil unless RAILS_ENV == 'development'

# Copy Assets over

Dir.glob("#{RAILS_ROOT}/vendor/modules/[a-z]*") do |file|
  if file =~ /\/([a-z_-]+)\/{0,1}$/
    mod_name = $1
    if File.directory?(file + "/public")
      FileUtils.mkpath("#{RAILS_ROOT}/public/components/#{mod_name}")
      FileUtils.cp_r(Dir.glob(file + "/public/*"),"#{RAILS_ROOT}/public/components/#{mod_name}/")
    end
  end
end


ActionMailer::Base.logger = nil unless ENV['RAILS_ENV'] == 'development'


if RAILS_ENV == 'test'
    if defaults_config_file['testing_domain']
      ActiveRecord::Base.establish_connection(YAML.load_file("#{RAILS_ROOT}/config/cms.yml")['test'])
      SystemModel.establish_connection(YAML.load_file("#{RAILS_ROOT}/config/cms.yml")['test'])
      DomainModel.activate_domain(Domain.find(defaults_config_file['testing_domain']).attributes,'production',false)
    else
      raise 'No Available Testing Database!'
    end
end 
if RAILS_ENV == 'cucumber' || RAILS_ENV == 'selenium'
    if defaults_config_file['cucumber_domain']
      ActiveRecord::Base.establish_connection(YAML.load_file("#{RAILS_ROOT}/config/cms.yml")['cucumber'])
      SystemModel.establish_connection(YAML.load_file("#{RAILS_ROOT}/config/cms.yml")['cucumber'])
      dmn = Domain.find(defaults_config_file['cucumber_domain']).attributes
      DomainModel.activate_domain(dmn,'production',false)
    else
      raise 'No Available Cucumber Database!'
    end
end


module Globalize
  class ModelTranslation
    def self.connection
      DomainModel.connection
    end
  end
end

Globalize::ModelTranslation.set_table_name('globalize_translations')

  
 
  
CACHE.servers =  [ 'localhost:11211' ]
ActionController::Base.session_options[:expires] = 1800
ActionController::Base.session_options[:cache] = CACHE





# Globalize Setup
include Globalize

# Load up some monkey patches
# For: Globalize and Date and Time classes
require 'webiva_monkey_patches'

# Base Language is always en-US - Language application was written in
Locale.set_base_language('en-US')

gem 'soap4r'

