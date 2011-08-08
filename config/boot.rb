require 'rubygems'
require 'openssl'
require 'yaml'
YAML::ENGINE.yamler= 'syck'

# Set up gems listed in the Gemfile.
gemfile = File.expand_path('../../Gemfile', __FILE__)

# Create Gemfile
require File.expand_path('../webiva_bundler', __FILE__)
Webiva::Bundler.setup

begin
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.setup
rescue Bundler::GemNotFound => e
  STDERR.puts e.message
  STDERR.puts "Try running `bundle install`."
  exit!
end if File.exist?(gemfile)
