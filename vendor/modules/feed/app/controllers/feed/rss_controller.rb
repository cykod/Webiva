# Copyright (C) 2009 Pascal Rettig.


class Feed::RssController < ParagraphController

  editor_header "Feed Paragraphs"

  editor_for :view_rss, :name => 'RSS Feed Display',  :features => ['rss_feed_view']
  editor_for :rss_auto_discovery, :name => 'RSS Autodiscovery Paragraph'

  def view_rss
    @options = ViewRssOptions.new(params[:view_rss] || @paragraph.data)
    
    return if handle_paragraph_update(@options)
  end
  
  class ViewRssOptions < HashModel
    default_options :rss_url => nil, :items => 0, :category => nil, :read_more => nil, :sanitize => 'yes', :cache_minutes => 5
    
    integer_options :items, :cache_minutes
    
    validates_presence_of :rss_url, :items
  end


  def rss_auto_discovery
    
    @options = RssAutoDiscoveryOptions.new(params[:rss_auto_discovery] || @paragraph.data)
    if handle_paragraph_update(@options)
      DataCache.expire_content('Feed')
      return
    end
    
    @available_feeds = [['--Show All RSS Feeds--']] + 
                        SiteNode.find(:all,:conditions =>  ['node_type = "M" AND module_name = "/feed/rss"' ]).collect { |md|
                          [md.node_path, md.id] }
  end
  
  class RssAutoDiscoveryOptions < HashModel
    default_options :module_node_id => nil
    
    integer_options :module_node_id
  
  end
end



