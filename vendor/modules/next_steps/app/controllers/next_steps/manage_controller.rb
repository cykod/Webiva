class NextSteps::ManageController < ModuleController
  component_info "NextSteps"
  permit :next_steps_manage
  
  cms_admin_paths "content",
    "Next Steps" => {:action => 'index'}
  
  active_table :steps_table, NextStepsStep,
    [:check, :action_text, :description_text, :page, "Document", :created_at]
  
  def display_steps_table(display=true)
    active_table_action('step') do |act,pid|
      case act
      when 'delete': NextStepsStep.destroy(pid)
      end
    end
    @table = steps_table_generate(params, :order => 'created_at DESC')
    render :partial => 'steps_table' if display
  end
  
  def index
    cms_page_path ["Content"], "Next Steps"
    display_steps_table(false)
  end
  
  def edit
    @step = NextStepsStep.find_by_id(params[:path][0]) || NextStepsStep.new
    cms_page_path ["Content", "Next Steps"],
      (@step.new_record? ? "Create a Step" : "Edit a Step")
    if request.post? && params[:step]
      if !params[:commit]
        redirect_to :action => 'index'
      elsif @step.update_attributes(params[:step])
        flash[:success] = "Saved Step"
        redirect_to :action => 'index'
      end
    end
  end
end
