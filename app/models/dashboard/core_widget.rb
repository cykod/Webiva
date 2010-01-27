
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

    return render_widget :text => 'Must reload widget to activate.'.t if first?

    render_widget :partial => '/emarketing/stats_widget'
  end

  class EmarketingStatsOptions < HashModel
  end

  def emarketing_charts
    require_js 'raphael/raphael-min.js'
    require_js 'raphael/g.raphael.js'
    require_js 'raphael/g.line.js'
    require_js 'raphael/g.bar.js'
    require_js 'raphael/g.dot.js'
    require_js 'raphael/g.pie.js'
    require_js 'emarketing.js'

    return render_widget :text => 'Must reload widget to activate.'.t if first?

    render_widget :partial => '/emarketing/charts_widget'
  end

  class EmarketingChartsOptions < HashModel
  end

  def rss_viewer

    rss_items = editor_widget.cache_fetch('Widget')

    if ! rss_items || rss_items.length == 0
      begin
	uri = URI.parse(@options.url)
	raise "Invalid URL" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

	rss_feed = ''
	timeout(@options.timeout_in_seconds) do
	  rss_feed = RSS::Parser.parse(Net::HTTP.get(uri),false)
	end

	rss_items = []
	rss_feed.items[0..@options.show_first-1].each { |item| rss_items << {'link' => item.link, 'title' => item.title, 'date' => item.pubDate} } if rss_feed.is_a?(RSS::Rss)
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
    attributes :url => nil, :show_first => 20, :timeout_in_seconds => 3, :valid_for => 5

    validates_presence_of :url, :show_first, :timeout_in_seconds, :valid_for
    validates_numericality_of :timeout_in_seconds, :greater_than_or_equal_to => 1, :less_than_or_equal_to => 30
    validates_numericality_of :valid_for, :greater_than_or_equal_to => 2
    validates_urlness_of :url

    integer_options :show_first, :timeout_in_seconds, :valid_for

    options_form(
         fld(:url, :text_field, :label => 'RSS Url'),
         fld(:show_first, :text_field, :description => 'items'),
         fld(:timeout_in_seconds, :text_field, :label => 'Fetch timeout', :description => 'seconds'),
         fld(:valid_for, :text_field, :label => 'Fetch feed every', :description => 'minutes')
         )
  end
end
