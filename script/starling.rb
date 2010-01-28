#!/usr/bin/env ruby

require 'yaml'

path = File.dirname(__FILE__)

config = YAML.load_file(path + "/../config/workling.yml")

env = ENV['RAILS_ENV'] || 'production'

config = config[env] 

port = config['listens_on'].split(":")[1]

cmd = "starling -d -P #{path}/../tmp/pids/starling.pid -q  #{path}/../tmp/starling_#{env}/ -p #{port}"
puts("Running #{env}:" + cmd)
`#{cmd}`
