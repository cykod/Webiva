# Copyright (C) 2009 Pascal Rettig.

class Manage::AccessController < CmsController # :nodoc: all
  layout "manage"

  skip_before_filter :validate_is_editor

  def login
  	cms_page_info "Website Editor Login",''
   
   if request.post? || params[:login_hash]
   
      if params[:login_hash]
        @editor_user = EditorLogin.find(:first,:conditions => ['login_hash = ? AND domain_id = ?',params[:login_hash],Configuration.domain_id])
        if(@editor_user)
          logged_in_user = EndUser.find(@editor_user.end_user_id)
          @editor_user.update_attribute(:login_hash,nil)
        end 
      else 
	      @user = ClientUser.new(params[:user])
	      @user.client_id = DomainModel.active_domain[:client_id]
	      logged_in_user = @user.attempt_login
	
	      if(!logged_in_user)
	        logged_in_user= EndUser.login_by_email(params[:user][:username],params[:user][:password])
	      end
      end
      
      if(logged_in_user)
        session[:user_id] = logged_in_user.id
        session[:user_model] = logged_in_user.class.to_s
        
        myself
        
        if myself.language
          session[:cms_language] = myself.language
          Locale.set(myself.language)
        else
          Locale.set(Configuration.languages[0])
          session[:cms_language] = Configuration.languages[0]
        end

        if  session[:lockout_current_url]
          redirect_to session[:lockout_current_url]
          session[:lockout_current_url] = nil
        elsif redirect_to(:controller => "/dashboard", :action => 'index')
        end
        return
      else
        flash.now[:notice] = "Invalid user/password combination"
      end
   else
      if myself.editor?
        redirect_to(:controller => "/dashboard", :action => 'index')
        return
      end
      @user = EndUser.new
   end
   
   if !request.ssl? 
     dmn = Domain.find(:first,:conditions => [ '`database`=? AND ssl_enabled=1',DomainModel.active_domain_db ])
     if dmn
      redirect_to "https://#{dmn.name}/website"
     end
   end

  end
  
  def denied
    cms_page_info [ 'Access Denied' ]
    if session[:user_id] && session[:user_model]
      if request.xhr?
        render :text => 'Access Denied'
      else
        render :action => 'denied'
      end
    else
      redirect_to :action => 'login'
    end
  end
  
  def login_redirect
    if myself.is_a?(ClientUser)
      redirect_to url_for(:controller => '/structure', :action => 'view')
    end
     
  end


  def logout 
    session[:user_id] = nil
    session[:user_model] = nil
    reset_session

    redirect_to(:action => 'login')
  end
  
 
end
