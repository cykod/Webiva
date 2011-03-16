require File.expand_path('../boot', __FILE__)

require 'yaml'

require 'rails/all'


class Rails::Plugin
  def webiva_remove_load_paths(file)
    dir =  File.dirname(file)
#    load_paths.each do |path|
#      ActiveSupport::Dependencies.load_once_paths.delete(path) if  path.include?(dir)
#    end
  end
end

# Auto-require default libraries and those for the current Rails environment.
Bundler.require :default, Rails.env

# Set up some constants
defaults_config_file = YAML.load_file(File.join(File.dirname(__FILE__),"defaults.yml"))

CMS_DEFAULTS = defaults_config_file

WEBIVA_LOGO_FILE = defaults_config_file['logo_override'] || nil 

CMS_DEFAULT_LANGUAGE = defaults_config_file['default_language'] || 'en'
CMS_DEFAULT_CONTRY = defaults_config_file['default_country'] || 'US'
CMS_CACHE_ACTIVE = defaults_config_file['active_cache'] || true
CMS_DEFAULT_DOMAIN = defaults_config_file['domain']

CMS_SYSTEM_ADMIN_EMAIL = defaults_config_file['system_admin']

DEFAULT_DATETIME_FORMAT = defaults_config_file['default_datetime_format'] || "%m/%d/%Y %I:%M %p"
DEFAULT_DATE_FORMAT = defaults_config_file['default_date_format'] || "%m/%d/%Y"

BETA_CODE = defaults_config_file['enable_beta_code'] || false



GIT_REPOSITORY = defaults_config_file['git_repository'] || nil 

CMS_DEFAULT_TIME_ZONE = defaults_config_file['time_zone'] || 'Eastern Time (US & Canada)'

#RAILS_ROOT = File.dirname(__FILE__) + "../" unless defined?(RAILS_ROOT)


module Webiva
  class Application < Rails::Application
    paths.config.database = "#{Rails.root}/config/cms.yml"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{config.root}/extras )

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
    config.paths.vendor.plugins = ["#{Rails.root}/vendor/plugins", "#{Rails.root}/vendor/modules" ]

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer



    config.time_zone = CMS_DEFAULT_TIME_ZONE


    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
    # config.i18n.default_locale = :de

    # Configure generators values. Many other options are available, be sure to check the documentation.
    # config.generators do |g|
    #   g.orm             :active_record
    #   g.template_engine :erb
    #   g.test_framework  :test_unit, :fixture => true
    # end

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters << :password
    config.filter_parameters << :password_confirmation
    config.filter_parameters << :payment
    config.filter_parameters << :contribute
  end
end
