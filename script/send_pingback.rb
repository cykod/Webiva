#!/usr/bin/ruby

require "xmlrpc/client"

source_uri = ARGV[0]
target_uri = ARGV[1]

pingback_url = ARGV.length > 2 ? ARGV[2] : target_uri.sub(/(http:\/\/.*?)\/.*/, '\1') + '/website/feedback/pingback'

server = XMLRPC::Client.new2(pingback_url)

ok, param = server.call2("pingback.ping", ARGV[0], ARGV[1])

if ok then
  puts "Response: #{param}"
else
  puts "Error:"
  puts param.faultCode 
  puts param.faultString
end
