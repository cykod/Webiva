
class WebivaNet::AdminController < ModuleController

 component_info 'WebivaNet', :description => 'Support for integration with Webiva.net', 
                              :access => :public
                              

 cms_admin_paths "options",
    "Webiva.net Options" => { :action => 'index' }
 
 permit 'editor_site_management'

 register_handler :structure, :wizard, "WebivaNet::SimpleSiteWizard"
 register_handler :webiva, :titlebar, "WebivaNet::TitlebarHandler"
 register_handler :action_panel, :templates, "WebivaNet::ThemesController"

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
    attributes :documentation_url => "http://www.webiva.net/doc/user", :themes_rss_url => "http://www.webiva.net/themes/rss"
  
  end
  
end
