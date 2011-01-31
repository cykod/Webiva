class LookingFor::ManageController < ModuleController
  component_info "LookingFor"
  permit :looking_for_manage
  
  cms_admin_paths "content",
    "Looking For" => {:action => 'index'}
  
  active_table :locations_table, LookingForLocation,
    [:check, :action_text, :description_text, :page, "Document", :created_at]
  
  def display_locations_table(display=true)
    active_table_action('location') do |act,pid|
      case act
      when 'delete': LookingForLocation.destroy(pid)
      end
    end
    @table = locations_table_generate(params, :order => 'created_at DESC')
    render :partial => 'locations_table' if display
  end
  
  def index
    cms_page_path ["Content"], "Looking For"
    display_locations_table(false)
  end
  
  def edit
    @location = LookingForLocation.find_by_id(params[:path][0]) || LookingForLocation.new
    cms_page_path ["Content", "Looking For"],
      (@location.new_record? ? "Create a Location" : "Edit a Location")
    if request.post? && params[:location]
      if !params[:commit]
        redirect_to :action => 'index'
      elsif @location.update_attributes(params[:location])
        flash[:success] = "Saved Location"
        redirect_to :action => 'index'
      end
    end
  end
end
