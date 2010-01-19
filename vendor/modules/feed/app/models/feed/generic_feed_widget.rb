
class Feed::GenericFeedWidget < Dashboard::WidgetBase

  widget :data_feed, :name => "Feed: Data Feed Widget", :title => "Information Feed"

  def data_feed
    set_icon 'news_icon.png'

    result = editor_widget.cache_fetch('Widget')
    
    if  !result
      eater = Feed::GenericFeedEater.new(@options.url,@options.format,@options.timeout)
      feed = eater.parse
      if !feed
        return render_widget :text => eater.error
      end

      feature = Feed::PageFeature.standalone_feature(options.site_feature_id)
      result = feature.feed_page_show_feature({ :output => feed })
      
      editor_widget.cache_put('Widget',result,nil,options.cache_time * 60)
    end
    
    render_widget :text => result
  end

  class DataFeedOptions < HashModel
    attributes :site_feature_id => nil, :url => nil, :cache_time => nil, :format => 'xml', :timeout => 3

    integer_options :cache_time, :timeout

    validates_presence_of :url, :site_feature_id

    validating_options :format, [['Xml','xml'],['JSON','json']]

    options_form(
                 fld(:site_feature_id,:select,:options => :available_features,:required => true),
                 fld(:url,:text_field,:size => 80,:required => true),
                 fld(:cache_time,:select,:options => :time_options),
                 fld(:format,:radio_buttons,:options => :format_select_options ),
                 fld(:timeout,:select, :options => :timeout_options)
                 )

    def available_features
      SiteFeature.select_options_with_nil('Feed Page Show Feature',:conditions => {  :feature_type => 'feed_page_show'})
    end

    def timeout_options
      (1..6).to_a.map {  |opt| ["%d seconds" / opt, opt]}
    end
    def time_options
      (1..20).to_a.map {  |opt| ["%d Minutes" / opt, opt]}
    end

  end

end
