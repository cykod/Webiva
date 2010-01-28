

class Dashboard::CoreWidget < Dashboard::WidgetBase #:nodoc:all

  widget :information, :name => "Display Static Information", :title => "Site Info"
  widget :emarketing_stats, :name => "Emarketing: Display Real Time Page Views", :title => "Real Time Page Views"
  widget :emarketing_charts, :name => "Emarketing: Uniques / Page Views Chart", :title => "Uniques / Page Views"

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

  @@welcome_text = <<-EOF
Welcome to the Webiva Content Management system. This is your
dashboard, which is a configurable overview of what's happening on your
site. Click on the pen page titlebar to edit your own widgets or click
on the icon to the right of the pen and select edit site widgets to edit
widgets that are common for for all site editors.

Check out the [Webiva Documentation](http://www.webiva.net/doc) for more details
on how work with webiva. If you have any questions take a look at the [Forums](http://www.webiva.net/forums) 
and post a question if you can't find an answer.

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
  end
  
end
