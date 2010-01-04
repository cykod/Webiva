
class <%= class_name %>::AdminController < ModuleController

 component_info '<%= class_name %>', :description => '<%= class_name.underscore.humanize.titleize %> support', 
                              :access => :public
                              
 # Register a handler feature
 register_permission_category :<%= name %>, "<%= class_name %>" ,"Permissions related to <%= class_name.underscore.humanize.titleize %>"
  
 register_permissions :<%= name %>, [ [ :manage, 'Manage <%= class_name.underscore.humanize.titleize %>', 'Manage <%= class_name.underscore.humanize.titleize %>' ],
                                  [ :config, 'Configure <%= class_name.underscore.humanize.titleize %>', 'Configure <%= class_name.underscore.humanize.titleize %>' ]
                                  ]
 cms_admin_paths "options",
    "<%= class_name.underscore.humanize.titleize %> Options" => { :action => 'index' },
    "Options" => { :controller => '/options' },
    "Modules" => { :controller => '/modules' }

 permit '<%= name %>_config'

 public 
 
 def options
    cms_page_path ['Options','Modules'],"<%= class_name.underscore.humanize.titleize %> Options"
    
    @options = self.class.module_options(params[:options])
    
    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated <%= class_name.underscore.humanize.titleize %> module options".t 
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
