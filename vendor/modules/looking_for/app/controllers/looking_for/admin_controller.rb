class LookingFor::AdminController < ModuleController

  component_info 'LookingFor', :description => 'Looking For support', 
                              :access => :public
                              
  # Register a handler feature
  register_permission_category :looking_for, "LookingFor" ,"Permissions related to Looking For"
  
  register_permissions :looking_for, [ [ :manage, 'Manage Looking For', 'Manage Looking For' ],
                                  [ :config, 'Configure Looking For', 'Configure Looking For' ]
                                  ]
  cms_admin_paths "options",
     "Looking For Options" => { :action => 'index' },
     "Options" => { :controller => '/options' },
     "Modules" => { :controller => '/modules' }

  permit 'looking_for_config'

  content_model :locations
  
  def self.get_locations_info
    [ { :name => 'Looking For',
        :permission => :looking_for_manage,
        :url => { :controller => 'looking_for/manage'}
    } ]
  end

  public 
 
  # def options
  #     cms_page_path ['Options','Modules'],"Looking For Options"
  #     
  #     @options = self.class.module_options(params[:options])
  #     
  #     if request.post? && @options.valid?
  #       Configuration.set_config_model(@options)
  #       flash[:notice] = "Updated Looking For module options".t 
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
