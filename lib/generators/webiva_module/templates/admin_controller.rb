
class <%= class_name %>::AdminController < ModuleController

  component_info '<%= class_name %>', :description => '<%= class_title %> support', 
                              :access => :public
                              
  # Register a handler feature
  register_permission_category :<%= name %>, "<%= class_name %>" ,"Permissions related to <%= class_title %>"
  
  register_permissions :<%= name %>, [ [ :manage, 'Manage <%= class_title %>', 'Manage <%= class_title %>' ],
                                  [ :config, 'Configure <%= class_title %>', 'Configure <%= class_title %>' ]
                                  ]
  cms_admin_paths "options",
     "<%= class_title %> Options" => { :action => 'index' },
     "Options" => { :controller => '/options' },
     "Modules" => { :controller => '/modules' }

  permit '<%= name %>_config'

  public 
 
  def options
    cms_page_path ['Options','Modules'],"<%= class_title %> Options"
    
    @options = self.class.module_options(params[:options])
    
    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated <%= class_title %> module options".t 
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
