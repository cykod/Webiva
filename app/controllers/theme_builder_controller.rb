
class ThemeBuilderController < CmsController
  permit 'editor_design_templates'

  layout 'manage'

  cms_admin_paths 'options', 
                  'Options' => { :controller => '/options' },
                  'Themes' => { :controller => '/templates' },
                  'Theme Builder' => {:action => 'index'}

  def index
    cms_page_path ['Options', 'Themes'], 'Theme Builder'

    @parser = ThemeBuilderParser.new params[:parser]

    if request.post? && @parser.valid?
      file = @parser.fetch
      return redirect_to :action => 'zones', :path => file.id if file
      @parser.errors.add(:url, 'is not an HTML document')
    end

    render :action => 'index'
  end

  def html
    @parser = ThemeBuilderParser.new :html_file_id => params[:path][0]
    render :partial => 'html'
  end

  def css
    @parser = ThemeBuilderParser.new :html_file_id => params[:path][0]
    render :inline => @parser.editor_css, :content_type => 'text/css'
  end

  def zones
    cms_page_path ['Options', 'Themes', 'Theme Builder'], 'Select Zones'

    @parser = ThemeBuilderParser.new :html_file_id => params[:path][0], :setting_up_theme => true

    unless @parser.is_html_file?
      redirect_to :action => 'index'
      return
    end

    if request.post?
      @parser.theme_html = params[:parser][:theme_html]
      @parser.theme_name = params[:parser][:theme_name]
      if @parser.valid?
        site_template = @parser.create_site_template
        return redirect_to :controller => '/templates', :action => 'edit', :path => site_template.id
      end
    else
      cnt = SiteTemplate.count
      @parser.theme_name = "Theme #{cnt+1}"
    end

    require_css 'theme_builder.css'
    require_js 'theme_builder.js'
  end
end
