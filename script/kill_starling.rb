#!/usr/bin/env ruby

require 'yaml'

path = File.dirname(__FILE__)

pid = `cat #{path}/../tmp/pids/starling.pid`
`kill #{pid}` 
