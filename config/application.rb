require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

class Rails::Plugin
  def webiva_remove_load_paths(file)
    dir =  File.dirname(file)
#    load_paths.each do |path|
#      ActiveSupport::Dependencies.load_once_paths.delete(path) if  path.include?(dir)
#    end
  end
end

module Webiva
  class Application < Rails::Application
    paths.config.database = "#{Rails.root}/config/cms.yml"

    config.webiva_defaults = YAML.load_file(File.join(File.dirname(__FILE__),"defaults.yml"))

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{config.root}/extras )
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
    config.paths.vendor.plugins = ["#{Rails.root}/vendor/plugins", "#{Rails.root}/vendor/modules" ]

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure generators values. Many other options are available, be sure to check the documentation.
    # config.generators do |g|
    #   g.orm             :active_record
    #   g.template_engine :erb
    #   g.test_framework  :test_unit, :fixture => true
    # end

    config.action_view.javascript_expansions[:defaults] = []
    config.action_view.javascript_expansions[:legacy] = ['overlib/overlib', 'prototype', 'effects', 'dragdrop', 'controls', 'builder', 'slider', 'swfobject', 'tiny_mce/tiny_mce', 'redbox']

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters << :password
    config.filter_parameters << :password_confirmation
    config.filter_parameters << :payment
    config.filter_parameters << :contribute
  end
end
