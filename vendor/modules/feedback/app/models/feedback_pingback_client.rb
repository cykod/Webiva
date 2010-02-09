require 'hpricot'
require 'open-uri'
require 'xmlrpc/client'
require 'net/http'
require 'uri'

class FeedbackPingbackClient
  attr_accessor :source_uri, :target_uri, :pingback_uri

  def initialize(source_uri, target_uri)
    @source_uri = source_uri
    @target_uri = target_uri
  end

  def pingback_uri
    return @pingback_uri if @pingback_uri

    begin
      # Check the response header for X-Pingback
      url = URI.parse(self.target_uri)
      Net::HTTP.start(url.host, url.port) {|http|
	response = http.head(url.path)
	@pingback_uri = response['X-Pingback'] if response
	return @pingback_uri if @pingback_uri
      }

      # Check for <link rel="pingback" href="..." /> in the body
      target_html = retrieve_target_content(self.target_uri)
      parser = Hpricot(target_html)
      elem = (parser / :link).find do |link|
	link[:rel] == 'pingback'
      end
      @pingback_uri = elem[:href] if elem
    rescue Exception => e
    end

    @pingback_uri
  end

  def retrieve_target_content(target_uri)
    return open(target_uri) if target_uri =~ /^http:\/\//
    target_uri
  end

  def send_pingback
    raise "pingback uri not found" unless self.pingback_uri

    server = XMLRPC::Client.new2(self.pingback_uri)
    server.call2("pingback.ping", self.source_uri, self.target_uri)
  end
end
