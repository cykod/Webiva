require 'rss/2.0'

class Dashboard::CoreWidget < Dashboard::WidgetBase #:nodoc:all

  widget :information, :name => "Display Static Information", :title => "Site Info"
  widget :emarketing_stats, :name => "Emarketing: Display Real Time Page Views", :title => "Real Time Page Views"
  widget :emarketing_charts, :name => "Emarketing: Uniques / Page Views Chart", :title => "Uniques / Page Views"
  widget :rss_viewer, :name => "Display RSS Feeds", :title => 'RSS Feed'

  def information
    set_icon 'news_icon.png'

    render_widget :text => @options.body_html
  end

  class InformationOptions < HashModel
    attributes :content_filter => "markdown", :body => "", :title => "Information", :body_html => ""
    validates_presence_of :body

    def validate
      self.body_html = ContentFilter.filter(self.content_filter,self.body)
    end

    options_form(
         fld(:content_filter, :select, :options => :content_filter_options),
         fld(:body,:text_area, :cols => 50, :rows => 10)
         )

    def content_filter_options
      ContentFilter.filter_options
    end
  end

  def emarketing_stats
    require_js 'emarketing.js'
    set_icon 'organize_icon.png'

    return render_widget :text => 'Must reload widget to activate.'.t if first?

    render_widget :partial => '/emarketing/stats_widget'
  end

  class EmarketingStatsOptions < HashModel
  end

  def emarketing_charts
    set_icon 'poll_icon.png'
    require_js 'emarketing.js'

    return render_widget :text => 'Must reload widget to activate.'.t if first?

    render_widget :partial => '/emarketing/charts_widget'
  end

  class EmarketingChartsOptions < HashModel
  end

  def rss_viewer
    set_icon 'news_icon.png'
    rss_items = editor_widget.cache_fetch('Widget')

    set_title_link @options.url

    if ! rss_items || rss_items.length == 0
      begin
        uri = URI.parse(@options.url)
        raise "Invalid URL" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

        feed_data = nil
        timeout(@options.timeout_in_seconds) do
          data_feed = Net::HTTP.get_response(uri)
          case data_feed
          when Net::HTTPSuccess;  feed_data = data_feed
          when Net::HTTPRedirection; feed_data =  Net::HTTP.get_response(URI.parse(data_feed['location']))
          end
        end
        rss_feed =  RSS::Parser.parse(feed_data.body.to_s,false)

        rss_items = []
        rss_feed.items[0..@options.show_first-1].each do |item|
          pubDate = Time.at item.pubDate.to_i
          if @options.show_description
            description = truncate(Util::TextFormatter.text_plain_generator(item.description),:length => 250)
          end
          rss_items << {'link' => item.link, 'title' => item.title, 'date' => pubDate, 'description' => description}
        end if rss_feed.is_a?(RSS::Rss)
      rescue TimeoutError
        editor_widget.cache_put('Widget', [], nil, @options.valid_for.minutes)
        logger.warn( "Timed out fetching rss feed for #{@options.url}" )
        render_widget :text => 'Timed out fetching RSS feed.'
        return
      rescue Exception => e
        editor_widget.cache_put('Widget', [], nil, @options.valid_for.minutes)
        logger.warn( "failed to fetch rss feed for #{@options.url}, errror: #{e}" )
        render_widget :text => 'Failed to fetch RSS feed.'
        return
      end

      editor_widget.cache_put('Widget', rss_items, nil, @options.valid_for.minutes)
    end

    render_widget :partial => '/dashboard/rss_viewer', :locals => {:rss_items => rss_items, :url => @options.url}
  end

  class RssViewerOptions < HashModel
    attributes :url => nil, :show_first => 20, :timeout_in_seconds => 3, :valid_for => 5, :show_description => false

    validates_presence_of :url, :show_first, :timeout_in_seconds, :valid_for
    validates_numericality_of :timeout_in_seconds, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 30
    validates_numericality_of :valid_for, :greater_than_or_equal_to => 2
    validates_urlness_of :url

    boolean_options :show_description

    integer_options :show_first, :timeout_in_seconds, :valid_for

    options_form(
         fld(:url, :text_field, :label => 'RSS Url'),
         fld(:show_first, :text_field, :unit => ' items'),
         fld(:show_description, :radio_buttons, :description => 'Show the first 250 characters of text.',:options => :yes_no),
         fld(:timeout_in_seconds, :text_field, :label => 'Fetch timeout', :unit => ' seconds'),
         fld(:valid_for, :text_field, :label => 'Fetch feed every', :unit => ' minutes')
         )
    def yes_no
      [['Yes'.t,true],['No'.t,false]]
    end
  end


  @@welcome_text = <<-EOF
Welcome to the Webiva Content Management system. This is your
dashboard, which is a configurable overview of what's happening on your
site. Click on the pen icon in the page titlebar to edit your own widgets or click
on the icon to the right of the pen and select 'edit site widgets' to edit
widgets that are common for for all site editors.

Check out the [Webiva Documentation](http://www.webiva.net/doc) for more details
on how work with Webiva. If you have any questions take a look at the [Forums](http://www.webiva.net/forum) 
and post a question if you can't find an answer already there.

   - The Webiva Team

EOF

  def self.add_default_widgets
    SiteWidget.create_widget("/dashboard/core_widget", "information",
                             :column => 0,
                             :weight => 0,
                             :title => "Welcome to Webiva",
                             :data =>  InformationOptions.new(:body => @@welcome_text).to_hash)
    SiteWidget.create_widget("/dashboard/core_widget", "emarketing_charts",
                             :column => 1,
                             :weight => 0,
                             :title => "Uniques / Page Views",
                             :data =>  EmarketingChartsOptions.new({ }).to_hash)
    SiteWidget.create_widget("/dashboard/content_node_widget", "updates",
                             :column => 0,
                             :weight => 1,
                             :title => "Updated Site Content",
                             :data =>  Dashboard::ContentNodeWidget::UpdatesOptions.new({ }).to_hash)
    SiteWidget.create_widget("/dashboard/core_widget", "rss_viewer",
                             :column => 2,
                             :weight => 0,
                             :title => "Webiva.net News",
                             :data =>  RssViewerOptions.new(:url => 'http://www.webiva.net/news/rss', :show_description => true,:items => 10).to_hash)
  end
  

end
