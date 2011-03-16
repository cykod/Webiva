
class SimpleContent::ManageController < ModuleController
  permit 'simple_content_manage'

  component_info 'SimpleContent'

  cms_admin_paths 'content', 
                  'Content' => { :controller => '/content' },
                  'Simple Content Models' => { :action => 'index' }

  # need to include 
  include ActiveTable::Controller
  active_table :simple_content_table,
                SimpleContentModel,
                [ hdr(:icon, '', :width=>10),
                  hdr(:string, :name),
                  :updated_at,
                  :created_at
                ]

  def index
    cms_page_path ['Content'], 'Simple Content Models'

    if SimpleContentModel.count == 0
      redirect_to :action => 'create'
      return
    end

    simple_content_table(false)
  end

  def simple_content_table(display=true)
    active_table_action 'simple_content' do |act,ids|
      case act
      when 'delete': SimpleContentModel.delete(ids)
      end
    end

    @active_table_output = simple_content_table_generate params, :order => 'name'
    
    render :partial => 'simple_content_table' if display
  end

  def create(popup=false)
    cms_page_path ['Content', 'Simple Content Models'], 'Create Simple Content Model'

    @content_model = SimpleContentModel.new

    if request.post? && params[:content_model]
      if @content_model.update_attributes(params[:content_model])
        if popup
          redirect_to :action => 'popup_model', :path => @content_model.id, 'para_index' => @paragraph_index
        else
          redirect_to :action => 'edit', :path => @content_model.id
        end
      end
    end
  end

  def edit(popup=false)
    cms_page_path ['Content', 'Simple Content Models'], 'Edit Simple Content Model'

    @content_model = SimpleContentModel.find(params[:path][0])

    if request.post? && params[:content_model]
      if @content_model.update_attributes(params[:content_model])
        @saved = true
	redirect_to :action => 'index' unless popup
      end
    end

    @exclude_field_options = [:hidden, :exclude, :unique, :folder_id]
    @field_types = ContentModel.simple_content_field_options
  end

  def new_field
    @content_field = ContentHashModelField.new(nil, params[:add_field])
    @content_field.field_options={}
    @new_field = true

    @exclude_field_options = [:hidden, :exclude, :unique, :folder_id]

    if !@content_field.valid?
      render :inline => "<script>alert('#{jvh("Invalid Field: " + @content_field.errors.full_messages.join(",")) }');</script>"
    else
      render :partial => 'edit_field', :locals => { :fld => @content_field , :field_index => params[:field_index].to_i}
    end
  end

  def popup_model
    @paragraph_index = params[:para_index]

    edit(true)

    @reload_url = "?para_index=#{@paragraph_index}&"

    render :action => 'edit', :layout => 'manage_window'
  end

  def popup_create
    @paragraph_index = params[:para_index]

    create(true)

    @reload_url = "?para_index=#{@paragraph_index}&"

    render :action => 'create', :layout => 'manage_window' if @content_model.id.nil?
  end
end
