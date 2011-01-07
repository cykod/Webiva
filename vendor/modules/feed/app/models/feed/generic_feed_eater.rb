require 'timeout'

class Feed::GenericFeedEater 

  def initialize(url,format='json',timeout_seconds=3)
    @url = url
    @format = format
    @timeout_seconds = timeout_seconds
  end

  attr_reader :output, :error

  def parse
    begin
      timeout(@timeout_seconds) do
        uri = URI.parse(@url)
        raise "Invalid URL" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        @response_string = self.get(uri)
      end
    rescue TimeoutError
      @error = "Timeout"
      return nil
    rescue Exception => e
      @error = e.to_s
      return nil
    end

    begin 
      if @format == 'json'
        @output = ActiveSupport::JSON.decode(@response_string)
      elsif @format == 'xml'
        @output = Hash.from_xml(@response_string)
      else
        raise 'Invalid Parsing Format'
      end
    rescue Exception => e
      @error = e.to_s
      nil
    end

    @output    
  end

  def get(uri)
    Net::HTTP.start(uri.host, uri.port) do |http|
      req = Net::HTTP::Get.new(uri.request_uri)
      req.basic_auth uri.user, uri.password if uri.user
      response = http.request(req)
      response.body.to_s
    end
  end
end
