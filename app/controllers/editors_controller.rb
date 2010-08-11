# Copyright (C) 2009 Pascal Rettig.

class EditorsController < CmsController  # :nodoc: all

  layout 'manage'
  
  permit 'editor_editors'

 include ActiveTable::Controller   
  active_table :editor_table,
                EndUser,
                [ ActiveTable::IconHeader.new(''),
                  ActiveTable::StringHeader.new('email', :label => 'Email'),
                  ActiveTable::StringHeader.new('last_name', :label => 'Last Name'),
                  ActiveTable::StringHeader.new('first_name', :label => 'First Name'),
                  ActiveTable::OptionHeader.new('user_classes.id', :label => 'User Class', :options => :user_classes )
                ]

  protected
  def user_classes
    UserClass.options(true)
  end


  public
  
  def display_editor_table(display=true)

     active_table_action('user') do |act,user_ids|
      case act
        when 'delete':
          EndUser.destroy(user_ids)
        end
     end
    
     @active_table_output = editor_table_generate params, :per_page => 25, 
                                                          :include => :user_class,
                                                          :conditions => 'user_classes.editor = 1 AND client_user_id IS NULL'
     render :partial => 'editor_table' if display
  end
  
  
  # Editor Editing
  def index
    cms_page_info([ [ 'Options', url_for(:controller => 'options') ], 'Site Editors' ], 'options' )
  
    
    display_editor_table(false)
  end
  
  
  def create
      cms_page_info([ [ 'Options', url_for(:controller => 'options') ],
                      [ 'Site Editors', url_for(:controller => 'editors') ],
                      'Create Editor' ], 'options' )
  
      user_class_id = params[:user_options].delete(:user_class_id) if params[:user_options]
      @user = EndUser.new(params[:user_options])
      
      if request.post? && params[:commit]
	@user.user_class_id = user_class_id
        @user.registered = true
        @user.user_level = 3
        if @user.save
	  @user.update_editor_login
          flash[:notice] = 'Created Editor'.t
          redirect_to :action => 'index'
          return
        end
      elsif request.post?
        return redirect_to :action => 'index'
      end
      
     render :action => 'edit'
  end  
  
  def edit
    cms_page_info([ [ 'Options', url_for(:controller => 'options') ] ,
		    [ 'Site Editors', url_for(:controller => 'editors') ],
		    'Edit Editor' ], 'options' )
    
    user_id = params[:path][0]
    
    user_class_id = params[:user_options].delete(:user_class_id) if params[:user_options]
    @user = EndUser.find(user_id)
    
    if request.post? && params[:commit]
      @user.user_class_id = user_class_id
      if @user.update_attributes(params[:user_options])
        @user.update_domain_emails
        @user.update_editor_login
	flash[:notice] = 'Saved User'.t 
        redirect_to :action =>'index'
        return
      end
    elsif request.post?
      return redirect_to :action => 'index'
    end
    
    @editing=true
    
  end
  
  def view
    cms_page_info([ [ 'Options', url_for(:controller => 'options') ],
		    [ 'Site Editors', url_for(:controller => 'editors') ], 
		    'View Editor' ], 'options' )
    
    user_id = params[:path][0]
    
    @user = EndUser.find(user_id)
  end
  
  def delete
    user_id = params[:user_id]
    member = EndUser.find_by_id(user_id)
    
    if member && member.destroy
      flash[:notice] = 'Deleted Editor: %s' / member.name
    end
    
    
    editor_update  
  end
  
  
end
