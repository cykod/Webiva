#!/usr/bin/ruby

require 'rubygems'
require 'memcache'

ENV['RAILS_ENV'] ||= (ARGV[0] || 'production')
ENV['HOME'] ||= '/home/webiva'

workling_config_file = YAML.load_file(File.join(File.dirname(__FILE__), "../config/workling.yml"))

client = MemCache.new workling_config_file[ENV['RAILS_ENV']]['listens_on']

client.set 'mail_template_mailer_workers__do_work', :mail => STDIN.read
