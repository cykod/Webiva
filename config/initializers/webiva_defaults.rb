
Webiva::Application.configure do
  config.webiva_defaults = YAML.load_file("#{Rails.root}/config/defaults.yml")
  config.webiva_defaults['default_language'] ||= 'en'
  config.webiva_defaults['default_country'] ||= 'US'
  config.webiva_defaults['active_cache'] ||= true
  config.webiva_defaults['default_datetime_format'] ||= "%m/%d/%Y %I:%M %p"
  config.webiva_defaults['default_date_format'] ||= "%m/%d/%Y"
  config.webiva_defaults['enable_beta_code'] ||= false
  config.webiva_defaults['time_zone'] ||= 'Eastern Time (US & Canada)'
  config.webiva_defaults['editor_login'] || false
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
