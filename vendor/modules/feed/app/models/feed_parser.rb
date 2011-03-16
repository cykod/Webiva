# Copyright (C) 2009 Pascal Rettig.

require  'rss/2.0'

class FeedParser

  def self.delayed_feed_parser(args)
     rss_feed = nil
     begin
       http = open(args[:rss_url])
       response = http.read
       rss_feed = RSS::Parser.parse(response,false)
     rescue Exception => e
       return nil
     end
     rss_feed = { :feed => rss_feed }
     DomainModel.remote_cache_put(args,rss_feed)
     rss_feed    
  end

end
