# Copyright (C) 2009 Pascal Rettig.

class Manage::UsersController < CmsController

  # need to be at least a client admin
  permit 'client_admin'

  before_filter :validate_admin
  def validate_admin
    unless myself.client_user.system_admin?
      redirect_to :controller => '/manage/system'
      return false
    end
    
  end

  layout "manage"

  def index
    cms_page_info [ ["System",url_for(:controller => '/manage/system',:action => 'index') ], 
                    "Client Users"
                 ],"system"
    
    if myself.client_user.system_admin?
      session[:active_client_company] ||= myself.client_user.client_id 
      session[:active_client_company] = params[:active_client_company] if params[:active_client_company]
      
      @active_client = session[:active_client_company]
      @client = Client.find(@active_client)
      @clients = Client.find(:all,:order => 'name')
    else 
      @client = myself.client_user.client
    end
  
    @users = @client.client_users.find(:all, :order => 'username')
    
    render :action => 'list'
  end
  
  def edit
    cms_page_info [ ["System",url_for(:controller => '/manage/system',:action => 'index') ], 
                    [ "Client Users", url_for(:action => 'index') ],
                    "Edit User"
                 ],"system"
  
    @client_user = myself.client_user.client.client_users.find_by_id(params[:path][0]) || myself.client_user.client.client_users.new
    @create_user = @client_user.id ?  false : true
    
    if request.post? 
      params[:client_user][:client_admin] = false unless params[:client_user][:client_admin]
      del params[:client_user][:system_admin] if params[:client_user][:system_admin]
      params[:client_user][:client_id] = myself.client_user.client_id
      if @client_user.update_attributes(params[:client_user])
        redirect_to :action => 'index'
        return
      end
    end
  end
  
  def edit_all
    cms_page_info [ ["System",url_for(:controller => '/manage/system',:action => 'index') ], 
                    [ "Client Users", url_for(:action => 'index') ],
                    "Edit User"
                 ],"system"
     # edit all func is only for system admins
    permit 'system_admin' do
      @client_user = ClientUser.find_by_id(params[:path][0]) || ClientUser.new(:client_id => session[:active_client_company])
      @create_user = @client_user.id ?  false : true
    
      
      if request.post? 
      
        params[:client_user][:client_admin] = false unless params[:client_user][:client_admin]
        params[:client_user][:system_admin] = false unless params[:client_user][:system_admin]
        
        if @client_user.update_attributes(params[:client_user])
          redirect_to :action => 'index'
          return
        end
      end
    end
  
    render :action => 'edit'
  end

  def destroy
    @client_user = myself.client_user.client.client_users.find(:first, :conditions => ['id = ?',params[:path][0]]);

    if @client_user
      if @client_user.destroy
        flash[:notice] = "Deleted User: #{@client_user.username}"
      end
    end

    redirect_to :action => 'index'

  end
end
