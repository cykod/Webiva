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
      url = URI.parse(self.target_uri)
      Net::HTTP.start(url.host, url.port) do |http|
	http.request_get(url.path) do |response|

	  # Check the response header for X-Pingback
	  @pingback_uri = response['X-Pingback'] if response['X-Pingback']
	  return @pingback_uri if @pingback_uri

	  # Check the page for a pingback <link>
	  if response.body =~ /<link rel="pingback" href="([^"]+)" ?\/?>/
	    @pingback_uri = $1.gsub('&amp;', '&').gsub('&lt;', '<').gsub('&gt;', '>').gsub('&quot;', '"')
	  end
	end
      end
    rescue Exception => e
    end

    @pingback_uri
  end

  def send_pingback
    raise "pingback uri not found" unless self.pingback_uri

    server = XMLRPC::Client.new2(self.pingback_uri)
    server.call2("pingback.ping", self.source_uri, self.target_uri)
  end
end
