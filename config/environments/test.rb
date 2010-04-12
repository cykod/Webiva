# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# All your existing stuff
config.action_controller.allow_forgery_protection  = false


config.gem "cucumber", :lib => false, :version => "0.6.2"
config.gem "rspec", :lib => false, :version => "1.3.0"
config.gem "rspec-rails", :lib => false, :version => "1.3.2"
config.gem "database_cleaner", :lib => false, :version => '0.4.3'
config.gem "factory_girl",:lib => false,  :source => "http://gemcutter.org"
config.gem "webrat",:lib => false,  :version => "0.6.0"
config.gem "nokogiri", :lib => false, :version => "1.3.1"
config.gem "cucumber-rails", :lib => false, :version => "0.2.4"

