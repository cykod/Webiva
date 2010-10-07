
class Webform::AdminController < ModuleController
  component_info 'Webform', :description => 'Webform support', :access => :public

  content_model :webform

  # Register a handler feature
  register_permission_category :webform, "Webform" ,"Permissions related to Webform"
  
  register_permissions :webform, [[:manage, 'Manage Webform', 'Manage Webform']
                                 ]
  register_handler :webiva, :widget, 'WebformWidget'

  register_handler :user_segment, :fields, 'WebformFormResultSegmentField'

  cms_admin_paths "options",
    "Options" => { :controller => '/options' },
    "Modules" => { :controller => '/modules' }

  permit 'webform_config'

  content_node_type 'Webform Results', "WebformFormResult", :title_field => :title

  def self.get_webform_info
    [
      {:name => 'Webforms', :url => {:controller => '/webform/manage'}, :permission => 'webform_manage', :icon => 'icons/content/forms_icon.png'}
    ]
  end
end
