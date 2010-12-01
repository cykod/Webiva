
class Webform::ManageController < ModuleController
  permit 'webform_manage'

  component_info 'Webform'

  cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' },
                  'Webforms' => { :action => 'index' }

  # need to include
  include ActiveTable::Controller
  active_table :webform_table,
                WebformForm,
                [ :check,
                  hdr(:icon, '', :width=>28),
                  :check,
                  :name,
                  'Total results',
                  'New results',
                  hdr(:date_range, :updated_at, :width=>160),
                  hdr(:date_range, :created_at, :width=>160)
                ]

  def index
    cms_page_path ['Content'], 'Webforms'

    if WebformForm.count == 0
      redirect_to :action => 'create'
      return
    end

    webform_table(false)
  end

  def webform_table(display=true)
    active_table_action 'webform' do |act,ids|
      case act
      when 'delete': WebformForm.destroy(ids)
      end
    end

    @active_table_output = webform_table_generate params
    
    render :partial => 'webform_table' if display
  end

  def create
    cms_page_path ['Content', 'Webforms'], 'Create Webform'

    @content_model = WebformForm.new

    if request.post? && params[:content_model]
      if @content_model.update_attributes(params[:content_model])
        redirect_to :action => 'edit', :path => @content_model.id
      end
    end
  end

  def edit
    @content_model = WebformForm.find(params[:path][0])

    cms_page_path ['Content', 'Webforms'], @content_model.name

    if request.post? && params[:content_model]
      if @content_model.update_attributes(params[:content_model])
        @saved = true
	redirect_to :action => 'index'
      end
    end

    @exclude_field_options = [:exclude, :unique]
    @field_types = ContentModel.simple_content_field_options
  end

  def new_field
    @content_field = ContentHashModelField.new(nil, (params[:add_field] || {}))
    @content_field.field_options={}
    @new_field = true

    @exclude_field_options = [:exclude, :unique]

    if !@content_field.valid?
      render :inline => "<script>alert('#{jvh("Invalid Field: " + @content_field.errors.full_messages.join(",")) }');</script>"
    else
      render :partial => 'edit_field', :locals => { :fld => @content_field , :field_index => params[:field_index].to_i}
    end
  end

  def configure
    @content_model = WebformForm.find(params[:path][0])

    cms_page_path ['Content', 'Webforms'], @content_model.name

    if request.post? && params[:content_model]

      if params[:feature]
        @content_model.content_model_features = params[:feature]
      else
        @content_model.content_model_features =  []
      end

      if @content_model.update_attributes(params[:content_model])
        @saved = true
	#redirect_to :action => 'index'
      end
    end

    @available_features = [['--Select a feature to add--','']] + WebformForm.get_webform_handler_options
  end

  def add_feature
    @content_model = WebformForm.find(params[:path][0])

    @info = get_handler_info(:content,:feature,params[:feature_handler])
    
    if @info 
      @feature = ContentHashModelFeature.new nil
      @feature.feature_handler = @info[:identifier]    
      render :partial => 'content_model_feature', :locals => { :feature => @feature, :idx => params[:index] }
    else
      render :nothing => true
    end  
  end 

  active_table :webform_result_table,
                WebformFormResult,
                [ hdr(:icon, '', :width=>10),
                  hdr(:boolean, :reviewed, :width=>100),
                  hdr(:string, :name, :width => 250),
                  hdr(:static, :snippet),
                  hdr(:date, :posted_at, :width=>160)
                ]

  def results
    @webform = WebformForm.find(params[:path][0])

    cms_page_path ['Content', 'Webforms'], @webform.name

    webform_result_table(false)
  end

  def webform_result_table(display=true)
    @webform ||= WebformForm.find(params[:path][0])

    active_table_action 'result' do |act,ids|
      case act
      when 'delete': WebformFormResult.delete(ids)
      when 'mark': WebformFormResult.update_all('reviewed = 1', :id => ids)
      when 'unmark': WebformFormResult.update_all('reviewed = 0', :id => ids)
      end
    end

    @active_table_output = webform_result_table_generate params, :order => 'webform_form_results.posted_at DESC', :conditions => ['webform_form_results.webform_form_id = ?',@webform.id ]
    
    render :partial => 'webform_result_table' if display
  end

  def result
    @webform = WebformForm.find(params[:path][0])
    @result = WebformFormResult.find(params[:path][1])

    @ajax = request.xhr?

    @table = params[:table]

    if request.post? && params[:result]
      if @result.update_attributes(params[:result])
        @saved = true
        if @ajax
          render :update do |page|
            page << 'SCMS.closeOverlay();'
            page << "$('#{@table}').onsubmit();" if @table
          end
          return
        else
          return redirect_to :action => 'results', :path => @webform.id
        end
      end
    end

    if @ajax
      render :action => 'result', :layout => false
    else
      cms_page_path ['Content', 'Webforms', [@webform.name, url_for(:action => :results, :path => @webform.id)]], 'Result'
      render :action => 'result'
    end
  end
end
