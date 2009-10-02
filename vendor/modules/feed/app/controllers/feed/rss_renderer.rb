# Copyright (C) 2009 Pascal Rettig.

require  'rss/2.0'

class Feed::RssRenderer < ParagraphRenderer
  
  paragraph :feed
  paragraph :view_rss
  paragraph :rss_auto_discovery, :cache => true
  
  def feed
    @options = paragraph.data || {}
    
    @handler_info = get_handler_info(:feed,:rss,@options['feed_type'])
    
    if(!@handler_info || !@options['feed_identifier'])
      data_paragraph :text => 'Reconfigure RSS Feed'.t
      return
    end
    
    @handler = @handler_info[:class].new(@options['feed_identifier'],@options)

    headers['Content-Type'] = 'text/xml'
    
    data = @handler.get_feed()
    if @handler_info[:custom]
      data_paragraph :text => render_to_string(:partial => @handler_info[:custom],:locals => { :data => data})
    else
      data_paragraph  :text => render_to_string(:partial => '/feed/rss/feed',:locals => { :data => data })
    end
  end
  
  feature :rss_feed_view, :default_feature => <<-FEATURE
    <div class='rss_feed'>
    <cms:feed>
      <h2><a <cms:href/>><cms:title/></a></h2>
      <cms:description/>
      <cms:items>
        <cms:item>
          <div class='rss_feed_item'>
          <h2><a <cms:href/>><cms:title/></a></h2>
          <cms:content/>
          </div>
        </cms:item>
      </cms:items>
    </cms:feed>
    <cms:no_feed>
      No Feed
    </cms:no_feed>    
    </div>
  FEATURE
  
  def rss_feed_view_feature(feature,data)
   parser_context = FeatureContext.new do |c|
    c.define_tag('feed') { |tag| data[:feed].blank? ? nil : tag.expand }
    c.define_tag('no_feed') { |tag| data[:feed].blank? ? tag.expand : nil }
    
    c.define_value_tag('feed:href') { |tag|  "href='#{data[:feed].channel.link}'" }
    c.define_value_tag('feed:title') { |tag| data[:feed].channel.title }
    c.define_value_tag('feed:description') { |tag| 
        data[:feed].channel.description 
    }

    c.define_tag('feed:no_items') { |tag| data[:feed].items.length == 0 ? tag.expand : nil }
    c.define_tag('feed:items') { |tag| data[:feed].items.length > 0 ? tag.expand : nil }
    c.define_tag('feed:items:item') do |tag|
      result = ''
      items = data[:feed].items
      unless data[:category].blank?
        items = items.find_all { |item| item.categories.detect { |cat| cat.content == data[:category] } }
      end 
      items = items[0..(data[:items]-1)] if data[:items] > 0
      items.each_with_index do |item,idx|
        tag.locals.item = item
        tag.locals.index = idx + 1
        tag.locals.first = idx == 0
        tag.locals.last = idx == data[:feed].items.length
        result << tag.expand
      end
      result
    end
    
    c.define_value_tag('feed:items:item:content') { |tag|
      if data[:read_more].blank?
       txt = tag.locals.item.description
      else
        txt = tag.locals.item.description.to_s.sub(data[:read_more],"[<a href='#{tag.locals.item.link}'>Read More..</a>]")
      end
     }
    c.define_value_tag('feed:items:item:href') { |tag| "href='#{tag.locals.item.link}'" }
    c.define_value_tag('feed:items:item:title') { |tag| tag.locals.item.title }
    c.define_value_tag('feed:items:item:author') { |tag| tag.locals.item.author }
    c.define_value_tag('feed:items:item:categories') { |tag| tag.locals.item.categories.map { |cat| cat.content }.join(", ") }
    c.define_value_tag('feed:items:item:description') { |tag| tag.locals.item.description }
     
    
   end
   
   parse_feature(feature,parser_context) 
  end
  
  
  def view_rss
    
    options = Feed::RssController::ViewRssOptions.new(paragraph.data || {})
    
    if options.rss_url.blank?
      render_paragraph :text => 'Configure Paragraph'
      return
    end
    
    target_string = 'ViewRss'
    display_string = "#{paragraph.id}"
  
    feature_output = nil
    valid_until,feature_output = DataCache.get_content("Feed",target_string,display_string) if !editor?
    
    if !feature_output || Time.now > valid_until
      begin
        http = open(options.rss_url)
        response = http.read
        rss_feed = RSS::Parser.parse(response,false)
      rescue Exception => e
        valid_until = Time.now + 5.minutes
        DataCache.put_content('Feed',target_string,display_string,[ valid_until, '' ]) if !editor?
        render_paragraph :text => ''
        return
      end
      data = { :feed => rss_feed, :items => options.items, :category => options.category, :read_more => options.read_more } 

      feature_output =  rss_feed_view_feature(get_feature('rss_feed_view'),data) 
      valid_until = Time.now + options.cache_minutes.to_i.minutes
      
      DataCache.put_content('Feed',target_string,display_string,[ valid_until, feature_output ]) if !editor?
    end
    
    render_paragraph :text => feature_output
  end
  
  def rss_auto_discovery
    @options = paragraph.data || {}
    
    if !@options[:module_node_id].blank? && @options[:module_node_id].to_i > 0
      @nodes = [ SiteNode.find_by_id(@options[:module_node_id]) ]
    else
      @nodes = SiteNode.find(:all,:conditions =>  ['node_type = "M" AND module_name = "/feed/rss"' ],:include => :page_modifier)
    end
    
    output = @nodes.collect do |nd|
          "<link rel='alternate' type='application/rss+xml' title='#{vh nd.page_modifier.modifier_data[:feed_title]}' href='#{vh nd.node_path}' />"
      end.join("\n")
    
    include_in_head(output)
    render_paragraph :nothing => true
  end
  

end
