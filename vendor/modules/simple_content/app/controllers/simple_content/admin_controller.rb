
class SimpleContent::AdminController < ModuleController

 component_info 'SimpleContent', :description => 'Simple Content support', :access => :public
                              
 # Register a handler feature
 register_permission_category :simple_content, "SimpleContent" ,"Permissions related to Simple Content"
  
 register_permissions :simple_content, [[:manage, 'Manage Simple Content', 'Manage Simple Content']
                                       ]
 cms_admin_paths "options",
    "Options" => { :controller => '/options' },
    "Modules" => { :controller => '/modules' }

 permit 'simple_content_config'

 content_action 'Simple Content Models', { :controller => '/simple_content/manage' }, 
   :icon => 'publications.gif', :permit => 'simple_content_manage'

end
