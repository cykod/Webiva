# Copyright (C) 2009 Pascal Rettig.


class Feed::RssDispatcher < ModuleDispatcher
  

  available_pages ['/', 'feed', 'RSS Feed', 'RSS Feed',false]
                  
                  
  
  
  def feed(args)
    simple_dispatch(1,'feed/rss','feed',:data => @site_node.page_modifier.modifier_data )
  end
  

end
