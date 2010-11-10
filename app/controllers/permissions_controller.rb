# Copyright (C) 2009 Pascal Rettig.

class PermissionsController < CmsController # :nodoc: all
  layout 'manage'
  
  
  permit 'editor_permissions' 
  
  protected 
  
  def assemble_permissions
    controllers = [ OptionsController, EditController ]
    
    controllers += ParagraphController.get_editor_controllers
    SiteModule.enabled_modules_info.each do |mod|
      controllers << mod.admin_controller_class
    end
    
    categories = []
    permissions = {}
    controllers.each do |ctrl|
      categories << ctrl.registered_permission_categories if ctrl.registered_permission_categories.length > 0
      ctrl.registered_permissions.each do |cat,elems|
        permissions[cat] ||= []
        permissions[cat] += elems
      end
    end
    
    [categories, permissions ]
  end
  
  def get_user_classes
    UserClass.find(:all,:order => 'built_in desc, name',:conditions => " id != 2 AND editor=1")
  end
  
  def get_all_user_classes
    UserClass.find(:all,:order => 'built_in desc, name',:conditions => " id != 2")
  end
  

  def permissions_grid_setup
    @categories, @permissions = assemble_permissions
    @user_classes = get_user_classes
    @all_user_classes = get_all_user_classes
    @access_tokens = AccessToken.find(:all,:conditions => { :editor => 1 })
  end
  
  public
  
  helper_method :column_color
  def column_color(idx)
    idx % 2 == 0 ? "class='alternate_row'" : ""
  end

  def index
    cms_page_info [ ['Options',url_for(:controller => 'options') ], 'Permissions' ], 'options'
  
    permissions_grid_setup
  end
  
  
  def update_permissions
    @categories, @permissions = assemble_permissions
    permissions = params[:permissions]
    category = params[:category]
    
    @user_classes = get_user_classes

    @access_tokens = AccessToken.find(:all,:conditions => { :editor => 1 })
    
    if @permissions[category.to_sym]
      @permissions[category.to_sym].each do |perm|
      
        permission_name = category + "_" + perm[0].to_s
        perms = permissions[permission_name] if permissions
        @user_classes.each do |cls|
          if perms && perms[cls.id.to_s]
            cls.has_role(permission_name,nil,true)
          else
            cls.has_no_role(permission_name,nil,true)
          end
        end

        @access_tokens.each do |token|
          if perms  && perms["token_" + token.id.to_s]
            token.has_role(permission_name,nil,true)
          else
            token.has_no_role(permission_name,nil,true)
          end
        end
      end
    end

    @access_tokens.map(&:save)
    @user_classes.map(&:save)
    
    render :nothing => true
  end

 def create_user_class
    @user_class = UserClass.new(:name => params[:name], :description => params[:description], :editor => params[:editor].to_s == '1' ? true : false)
    @user_class.save

    permissions_grid_setup
  end
  
  def delete_user_class
    @user_class = UserClass.find(:first,:conditions => [ 'id=? AND built_in=0',params[:user_class_id] ])
    @user_class.destroy if @user_class

    permissions_grid_setup
    
    render :action => 'update_permissions_grid'
  end
  
  def update_user_class
    @user_class = UserClass.find(:first, :conditions => [ 'id=? AND built_in=0',params[:user_class_id] ] )
    @user_class.update_attributes({ :name => params[:name], :description => params[:description] }) if @user_class

    permissions_grid_setup
  
    render :action => 'update_permissions_grid'
  end
    
    
end
