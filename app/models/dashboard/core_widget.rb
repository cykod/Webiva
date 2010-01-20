

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
end
