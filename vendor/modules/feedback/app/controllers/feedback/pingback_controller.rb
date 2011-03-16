require 'xmlrpc/server'

class Feedback::PingbackController < ApplicationController
  def initialize
    @server = XMLRPC::BasicServer.new
    @server.add_handler('pingback.ping') do |source_uri, target_uri|
      self.pingback_ping(source_uri, target_uri)
    end
  end

  def index
    if request.post?
      render :text => @server.process(request.body.read),
      :content_type => "text/xml; charset=utf-8", :layout => false
    else
      render :nothing => true
    end
  end

  protected
  def pingback_ping(source_uri, target_uri)
    begin
      @pingback = FeedbackPingback.process_incoming_ping source_uri, target_uri
      return "Ping from #{source_uri} to #{target_uri} registered. Thanks for linking to us."
    rescue FeedbackPingback::Error => e
      logger.error "Ping from #{source_uri} to #{target_uri} failed with code #{e.faultCode} because #{e.faultString}"
      raise e
    rescue Exception => e
      logger.error "Ping from #{source_uri} to #{target_uri} failed because #{e}"
      raise FeedbackPingback::Error.error
    end
  end
end

