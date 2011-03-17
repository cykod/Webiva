# Settings specified here will take precedence over those in config/environment.rb

Webiva::Application.configure do

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching             = false

  # Tell ActionMailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # All your existing stuff
  config.action_controller.allow_forgery_protection  = false

  testing_domain = config.webiva_defaults['testing_domain']

  raise 'No Available Testing Database!' unless testing_domain

  db_info = YAML.load_file("#{Rails.root}/config/cms.yml")['test']
  ActiveRecord::Base.establish_connection db_info
  SystemModel.establish_connection db_info
  DomainModel.activate_domain(Domain.find(testing_domain).attributes, 'migrator', false)
end
