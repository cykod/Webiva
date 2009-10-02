class RSSWorker < BackgrounDRb::Worker::Base
  require 'rss'
  require 'net/http'

  def do_work(args)
  end

  # This will fail since rss.parse will return non-serializable data
  def simple_rss
    Net::HTTP.start('www.mozilla.org') do |http|
      response = http.get('/news.rdf')
      fail response.code unless response.code == "200"
      rss = RSS::Parser.new(response.body)
      results[:parsed_rss] = rss.parse
    end
  end


end
RSSWorker.register
