
class <%= class_name %>::AdminController < ModuleController

 component_info '<%= class_name %>', :description => '<%= class_name.humanize %> support', 
                              :access => :public
                              
 # Register a handler feature
 register_permission_category :<%= name %>, "<%= class_name %>" ,"Permissions related to <%= class_name.humanize %>"
  
 register_permissions :<%= name %>, [ [ :manage, 'Manage <%= class_name.humanize %>', 'Manage <%= class_name.humanize %>' ],
                                  [ :config, 'Configure <%= class_name.humanize %>', 'Configure <%= class_name.humanize %>' ]
                                  ]
 cms_admin_paths "options",
    "<%= class_name.humanize %> Options" => { :action => 'index' }
 
 permit '<%= name %>_config'

 public 
 
 def options
    cms_page_path ['Options','Modules'],"<%= class_name.humanize %> Options"
    
    @options = self.class.module_options(params[:options])
    
    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated <%= class_name.humanize %> module options".t 
      redirect_to :controller => '/modules'
      return
    end    
  
  end
  
  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end
  
  class Options < HashModel
   # Options attributes 
   # attributes :attribute_name => value
  
  end
  
end
