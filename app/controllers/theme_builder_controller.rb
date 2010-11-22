
class ThemeBuilderController < CmsController
  permit 'editor_design_templates'

  layout 'manage'

  cms_admin_paths 'options', 
                  'Options' => { :controller => '/options' },
                  'Themes' => { :controller => '/templates' },
                  'Theme Builder' => {:action => 'index'}

  def index
    cms_page_path ['Options', 'Themes'], 'Theme Builder'

    if session[:theme_builder_worker_key]
      flash[:notice] = "Still fetching %s" / session[:theme_builder_url]
      return redirect_to :action => 'fetch'
    end

    @parser = ThemeBuilderParser.new params[:parser]

    if request.post? && @parser.valid?
      if @parser.html_file
        return redirect_to :action => 'zones', :path => @parser.html_file.id
      else @parser.url
        worker_key = @parser.run_worker :run_download
        session[:theme_builder_worker_key] = worker_key
        session[:theme_builder_url] = @parser.url
        return redirect_to :action => 'fetch'
      end

      @parser.errors.add(:url, 'is not an HTML document')
    end

    render :action => 'index'
  end

  def fetch
    cms_page_path ['Options', 'Themes', 'Theme Builder'], 'Fetching'
    @theme_url = session[:theme_builder_url]
    return redirect_to(:action => 'index') if @theme_url.blank?
  end

  def fetch_status
    results = Workling.return.get(session[:theme_builder_worker_key]) || {}
    processed = results[:processed]
    successful = results[:successful]
    html_file_id = results[:html_file_id]

    if processed && ! successful
      session.delete :theme_builder_worker_key
      session.delete :theme_builder_url
    end

    render :json => {:processed => processed, :successful => successful, :running => ! results.empty?, :html_file_id => html_file_id}
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

    if session[:theme_builder_worker_key]
      results = Workling.return.get(session[:theme_builder_worker_key]) || {}
      session.delete :theme_builder_worker_key
      session.delete :theme_builder_url
      return redirect_to :action => 'zones', :path => results[:html_file_id]
    end

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
