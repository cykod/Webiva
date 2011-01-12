class NextSteps::AdminController < ModuleController

  component_info 'NextSteps', :description => 'Next Steps support', 
                              :access => :public
                              
  # Register a handler feature
  register_permission_category :next_steps, "NextSteps" ,"Permissions related to Next Steps"
  
  register_permissions :next_steps, [ [ :manage, 'Manage Next Steps', 'Manage Next Steps' ],
                                  [ :config, 'Configure Next Steps', 'Configure Next Steps' ]
                                  ]
  cms_admin_paths "options",
     "Next Steps Options" => { :action => 'index' },
     "Options" => { :controller => '/options' },
     "Modules" => { :controller => '/modules' }

  permit 'next_steps_config'

  public 
 
  # def options
  #     cms_page_path ['Options','Modules'],"Next Steps Options"
  #     
  #     @options = self.class.module_options(params[:options])
  #     
  #     if request.post? && @options.valid?
  #       Configuration.set_config_model(@options)
  #       flash[:notice] = "Updated Next Steps module options".t 
  #       redirect_to :controller => '/modules'
  #       return
  #     end    
  #   
  #   end
  
  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end
  
  class Options < HashModel
   # Options attributes 
   # attributes :attribute_name => value
  
  end

end
