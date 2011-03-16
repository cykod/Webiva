

class DashboardController < CmsController #:nodoc:all

  permit :editor_site_management, :only => [ :site_widgets, :site_widget ]

  cms_admin_paths :dashboard,
    "Dashboard" => { :action => "index" },
    "Site Widgets" => {  :action =>"site_widgets"}


  def index
    cms_page_info 'Dashboard', 'dashboard',  myself.has_role?(:editor_site_management) ? 'CMSDashboard.pagePopup();' : nil

    if Rails.env == 'development'
      begin
        WorklingStatusWoker.async_do_work :nothing => true
      rescue Workling::QueueserverNotFoundError
        flash.now[:notice] = 'Background queue is not running please check your configuration.'
      end
    end

    @widget_columns = EditorWidget.assemble_widgets(myself)
    @widget_columns.each do |column|
      column.each do  |widget| 
        widget.render_widget(self) unless widget.hide? 
        if widget.includes
          widget.includes[:js].each { |js| require_js(js) } if widget.includes[:js]
          widget.includes[:css].each { |css| require_css(css) } if widget.includes[:css]
        end
      end
    end
  end


  def positions
    columns = [ params[:column_0]||[], params[:column_1]||[], params[:column_2]||[] ]
    EditorWidget.update_widget_positions(myself,columns)
    render :nothing => true
  end

  def edit
    @widget = EditorWidget.find_by_id(params[:widget_id]) || EditorWidget.new(:column => params[:column], :end_user_id => myself.id,:position => 0)
    @options = @widget.options if @widget.module
    
    if request.post? && params[:widget]
      @new_widget = @widget.new_record?
      if params[:commit] && @widget.update_attributes(params[:widget])
        @widget.render_widget(self,@new_widget)
        render :action => 'update_widget', :locals => { :widget => @widget }
        return
      end
    end
    
    @widget_modules = [['--Select Widget--',nil]] +  SiteWidget.widget_options(myself)
    render :action => 'edit', :layout => false
  end

  def remove
    @widget = EditorWidget.find_by_id_and_end_user_id(params[:widget_id],myself.id)
    if @widget.site_widget && !@widget.required?(myself)
      @widget.update_attributes(:hide => true)
      
    elsif !@widget.site_widget
      @widget.destroy
    else
      render :nothing => true
    end
   
  end

  def widget
    @widget = EditorWidget.find_by_id(params[:path][0],myself.id)
    @widget.update_attributes(:hide => false)
    @widget.render_widget(self)
    render :action => 'widget'
  end

  def show
    @widget = EditorWidget.find_by_id(params[:widget_id],myself.id)
    @widget.update_attributes(:hide => false)
    @widget.render_widget(self,true)
    render :action => 'show'
  end

  active_table :site_widgets_table, SiteWidget, [ :check, "Name", "Widget", :created_at, hdr(:number,:column), 
                                    hdr(:number,:weight),hdr(:boolean,:required),"Who" ]

  def display_site_widgets_table(display=true)

    active_table_action('widget') do |act,wids|
      SiteWidget.destroy(wids) if act == 'delete'
    end

    @tbl = site_widgets_table_generate(params, :order => "created_at DESC")

    render :partial => 'site_widgets_table' if display
  end

  def site_widgets
    cms_page_path ["Dashboard"], "Site Widgets"

    display_site_widgets_table(false)
  end

  def site_widget
    @widget = SiteWidget.find_by_id(params[:path][0]) || SiteWidget.new(:required => false)
    @options = @widget.options if @widget.module
    cms_page_path ["Dashboard", "Site Widgets"], @widget.new_record? ? "Add a Widget" : ["Edit %s Widget",nil,@widget.widget_description ]
    
    if request.post? && params[:widget]
      if params[:commit] && @widget.update_attributes(params[:widget])
        redirect_to :action => 'site_widgets'
      end
    end
    
    @widget_modules = [['--Select Widget--',nil]] +  SiteWidget.widget_options
  end

  def widget_options
    @options = SiteWidget.widget_options_from_identifier(params[:identifier])
    if @widget = SiteWidget.widget_from_identifier(params[:identifier])
      @widget_title = @widget[2][:title]
    end
    render :partial => 'widget_options', :locals => {  :options => @options }
  end


end
