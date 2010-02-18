#!/usr/bin/ruby

require File.dirname(__FILE__) + '/../config/boot'
require File.dirname(__FILE__) + '/../vendor/modules/feedback/app/models/feedback_pingback_client'

source_uri = ARGV[0]
target_uri = ARGV[1]

client = FeedbackPingbackClient.new source_uri, target_uri
client.pingback_uri = ARGV[2] if ARGV.length > 2

begin
  ok, param = client.send_pingback

  if ok then
    puts "Response: #{param}"
  else
    puts "Error: #{param.faultCode}"
    puts param.faultString
  end
rescue Exception => e
  puts "Error: #{e}"
end
