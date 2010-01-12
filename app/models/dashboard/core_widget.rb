

class Dashboard::CoreWidget < Dashboard::WidgetBase

  widget :information, :name => "Display Static Information", :title => "Site Info"

  widget :statistics, :name => "Display Website Statistics"


  def information
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

end
