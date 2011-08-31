# Copyright (C) 2009 Pascal Rettig.

require  'rss/2.0'

class Feed::RssRenderer < ParagraphRenderer
  
  paragraph :feed
  paragraph :view_rss
  paragraph :rss_auto_discovery, :cache => true
  
  def feed
    paragraph_data = (paragraph.data || {}).symbolize_keys
    
    @handler_info = get_handler_info(:feed,:rss,paragraph_data[:feed_type])

    
    if ! @handler_info
      data_paragraph :text => 'Reconfigure RSS Feed'.t
      return
    end
    
    handler_options_class = nil
    begin
      handler_options_class = "#{@handler_info[:class_name]}::Options".constantize
    rescue
    end

    if handler_options_class.nil?
      data_paragraph :text => 'Reconfigure RSS Feed'.t
      return
    end

    @options = handler_options_class.new(paragraph_data)
    @handler = @handler_info[:class].new(@options)

    @cache_id = site_node.id.to_s

    if @handler.respond_to?(:set_path)
      @handler.set_path(params[:path]) 
      @cache_id += DomainModel.hexdigest(params[:path].join("/"))
    end

    results = renderer_cache(nil,@cache_id, :skip => @options.timeout <= 0, :expires => @options.timeout*60) do |cache|
      data = @handler.get_feed
      data[:self_link] = Configuration.domain_link site_node.node_path
      if @handler_info[:custom]
	cache[:output] = render_to_string(:partial => @handler_info[:custom],:locals => { :data => data})
      else
	cache[:output] = render_to_string(:partial => '/feed/rss/feed',:locals => { :data => data })
      end
    end

    headers['Content-Type'] = 'text/xml'
    data_paragraph :text => results.output
  end
  
  feature :rss_feed_view, :default_feature => <<-FEATURE
    <div class='rss_feed'>
    <cms:feed>
      <h2><cms:link><cms:title/></cms:link></h2>
      <cms:description/>
      <cms:items>
        <cms:item>
          <div class='rss_feed_item'>
          <h3><cms:link><cms:title/></cms:link></h3>
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


  include ActionView::Helpers::DateHelper
  
  def rss_feed_view_feature(data)
    webiva_feature(:rss_feed_view,data) do |c|
    c.define_tag('feed') { |tag| data[:feed].blank? ? nil : tag.expand }
    c.define_tag('no_feed') { |tag| data[:feed].blank? ? tag.expand : nil }
    
    c.define_link_tag('feed:') { |t| data[:feed].channel.link }
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
    c.define_link_tag('feed:items:item:') { |t| t.locals.item.link }
    c.define_value_tag('feed:items:item:title') { |tag| tag.locals.item.title }
    c.define_value_tag('feed:items:item:author') { |tag| tag.locals.item.author }
    c.define_value_tag('feed:items:item:categories') { |tag| tag.locals.item.categories.map { |cat| cat.content }.join(", ") }
    c.define_value_tag('feed:items:item:description') { |tag| tag.locals.item.description }
    c.date_tag('feed:items:item:date') { |t| t.locals.item.date } 



    c.value_tag('feed:items:item:ago') { |t| 
       distance_of_time_in_words_to_now(t.locals.item.date).gsub('about','').strip if t.locals.item.date }

     
    
   end
   
  end
  
  
  def view_rss
    
    options = Feed::RssController::ViewRssOptions.new(paragraph.data || {})
    
    return render_paragraph :text => 'Configure Paragraph' if options.rss_url.blank?
    
    result = renderer_cache(nil,options.rss_url, :expires => options.cache_minutes.to_i.minutes) do |cache|
      rss_feed = delayed_cache_fetch(FeedParser,:delayed_feed_parser,{ :rss_url => options.rss_url },options.rss_url, :expires => options.cache_minutes.to_i.minutes)
      return render_paragraph :text => '' if !rss_feed

      data = { :feed => rss_feed[:feed], :items => options.items, :category => options.category, :read_more => options.read_more } 
      cache[:output] =  rss_feed_view_feature(data) 
      logger.warn('In Renderer Cache')
    end

    render_paragraph :text => result.output
  end
  
  def rss_auto_discovery
    @options = paragraph.data || {}
    
    if !@options[:module_node_id].blank? && @options[:module_node_id].to_i > 0
      @nodes = [ SiteNode.find_by_id(@options[:module_node_id]) ].compact
    else
      @nodes = SiteNode.find(:all,:conditions =>  ['node_type = "M" AND module_name = "/feed/rss"' ],:include => :page_modifier)
    end
    
    output = @nodes.collect do |nd|
      if nd.page_modifier 
        nd.page_modifier.modifier_data ||= {}
        "<link rel='alternate' type='application/rss+xml' title='#{vh nd.page_modifier.modifier_data[:feed_title]}' href='#{vh nd.node_path}' />"
      else
        nil
      end
    end.compact.join("\n")
    
    include_in_head(output)
    render_paragraph :nothing => true
  end
  

end
