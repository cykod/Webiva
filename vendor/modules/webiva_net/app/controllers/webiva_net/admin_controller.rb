
class WebivaNet::AdminController < ModuleController

 component_info 'WebivaNet', :description => 'Support for integration with Webiva.net', 
                              :access => :public
                              
 # register_permission_category :webiva_net, "WebivaNet" ,"Permissions related to Webiva.net"
  
 # register_permissions :webiva_net, [[ :manage, 'Manage Webiva.net', 'Manage Webiva.net' ],
 #                                    [ :config, 'Configure Webiva.net', 'Configure Webiva.net' ]
 #                                   ]

 cms_admin_paths "options",
    "Webiva.net Options" => { :action => 'index' }
 
 permit 'editor_site_management'

 register_handler :webiva, :titlebar, "WebivaNet::TitlebarHandler"

 public 
 
 def options
    cms_page_path ['Options','Modules'],"Webiva.net Options"
    
    @options = self.class.module_options(params[:options])
    
    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated Webiva.net module options".t 
      redirect_to :controller => '/modules'
      return
    end    
  
  end
  
  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end
  
  class Options < HashModel
    attributes :documentation_url => "http://www.webiva.net/doc/interface"
  
  end
  
end
