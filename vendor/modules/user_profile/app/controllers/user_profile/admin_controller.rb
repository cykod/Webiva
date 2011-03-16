
class UserProfile::AdminController < ModuleController

  component_info 'UserProfile', :description => 'User Profile support', 
    :access => :public

  cms_admin_paths "options",
    "Options" =>   { :controller => '/options' },
    "Modules" =>  { :controller => '/modules' },
    "User Profile Options" => { :action => 'index' }

  register_permission_category :user_profile, "UserProfile" ,"Permissions related to User Profile"
  register_handler :model, :end_user, "UserProfileUserHandler", :actions => [:after_save]
  register_handler :members, :view, "UserProfile::ManageController"

  register_handler :editor, :auth_user_edit_feature, "UserProfile::UserEditExtension"



  register_permissions :user_profile, [ [ :manage, 'Manage User Profile', 'Manage User Profile' ],
    [ :config, 'Configure User Profile', 'Configure User Profile' ]
  ]
  permit 'user_profile_config'

  linked_models :end_user, [ :user_profile_entry ] 

  def edit_profile_type
    @profile_type = UserProfileType.find_by_id(params[:path][0])  || UserProfileType.new
    cms_page_path ['Options','Modules',"User Profile Options"],
                     @profile_type.id ? ["Edit %s",nil,@profile_type.name] : "Create Profile Type"


    if request.post? && params[:user_profile_type] 
      if params[:commit]
        if @profile_type.update_attributes(params[:user_profile_type])
          flash[:notice] = "Saved Profile %s" / @profile_type.name
          redirect_to :action => 'options'
        end
      else
        redirect_to :action => 'options'
      end
    end

  end

  def content_model_fields
    @profile_type = UserProfileType.new(:content_model_id => params[:content_model_id])
    render :partial => 'content_model_fields'
  end

  def options
    create_default_profile_type 
    cms_page_path ['Options','Modules'],"User Profile Options"
    display_user_profile_table(display)
  end


  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end

  def create_default_profile_type
    if UserProfileType.count == 0
      UserProfileType.create_default_profile_type
      SiteModule.complete_module_initialization('user_profile')
    end
  end

  active_table :user_profile_table, UserProfileType, [ :check, :name, :content_model_id, hdr(:static,'user_classes') ]

  def display_user_profile_table(display=true)
    active_table_action 'user_profile' do |act,ids|
      case act
      when 'delete': UserProfileType.destroy(ids)
      end
    end
    @tbl = user_profile_table_generate params, :include => :user_profile_type_user_classes

    render :partial => 'user_profile_table' if display
  end

  # Dummy options model just to force visit to the module options page
  class Options < HashModel
    def validate 
      self.errors.add_to_base('Add Profile') if UserProfileType.count == 0
    end
  end
end
