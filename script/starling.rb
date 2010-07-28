#!/usr/bin/env ruby

require 'yaml'

path = File.dirname(__FILE__)

config = YAML.load_file(path + "/../config/defaults.yml") || {}

env = ENV['RAILS_ENV'] || 'production'

if !config['starling']
 if env == 'production'
  config['starling'] = 'localhost:15151'
 else
  config['starling'] = 'localhost:22122'
 end
end 

host = config['starling'].split(":")[0]
port = config['starling'].split(":")[1]

cmd = "starling -d -P #{path}/../tmp/pids/starling.pid -q  #{path}/../tmp/starling_#{env}/ -h #{host} -p #{port}"
puts("Running #{env}:" + cmd)
`#{cmd}`
