source :rubygems

gem 'rails', '2.3.4'

gem 'BlueCloth', '1.0.1', :require => 'bluecloth'
gem 'RedCloth', '4.2.3', :require => 'redcloth'
gem 'SyslogLogger', '1.4.0'
gem 'activerecord-activesalesforce-adapter', '2.0.0'
gem 'builder', '2.1.2'
gem 'daemons', '1.0.10'
gem 'database_cleaner', '0.4.3'
gem 'diff-lcs', '1.1.2'
gem 'eventmachine', '0.12.10'
gem 'gruff', '0.3.4'
gem 'highline', '1.6.1'
gem 'hoe', '1.12.2'
gem 'hpricot', '0.8.1'
gem 'httpclient', '2.1.5.2'
gem 'imagesize', '0.1.1'
gem 'json', '1.1.6'
gem 'json_pure', '1.2.0'
gem 'libxml-ruby', '1.1.3', :require => 'xml'
gem 'maruku', '0.6.0'
gem 'memcache-client', '1.7.7', :require => 'memcache'
gem 'mime-types', '1.16', :require => 'mime/types'
gem 'mysql', '2.8.1'
gem 'net-ssh', '2.0.11', :require => 'net/ssh'
gem 'nokogiri', '1.3.1'
gem 'polyglot', '0.2.9'
gem 'radius', '0.5.1'
gem 'rmagick', '2.9.2', :require => 'RMagick'
gem 'slave', '1.2.1'
gem 'soap4r', '1.5.8', :require => 'soap/soap'
gem 'starling', '0.10.1'
gem 'syntax', '1.0.0'
gem 'system_timer', '1.0'
gem 'term-ansicolor', '1.0.4'
gem 'treetop', '1.4.3'

group :development do
  gem 'ghost', '0.2.8'
  gem 'rubyforge', '2.0.3'
end

# For now, the rspec gems need to be present at all times (even during
# deployment) since we have a lib/tasks/rspec.rake file present, and rake will
# break if the gem isn't loaded. I believe rspec 2.x will remove this
# dependency and allow us to put these gems back in the :test group, excluding
# them from deployment.
gem 'rspec', '1.3.0'
gem 'rspec-rails', '1.3.2'

group :test do
  gem 'cucumber', '0.6.2'
  gem 'cucumber-rails', '0.2.4'
  gem 'factory_girl', '1.2.3'
  gem 'selenium-client', '1.2.18'
  gem 'webrat', '0.6.0'
end