# Copyright (C) 2009 Pascal Rettig.


require 'singleton' 


# Base class for displaying SiteNode content renderered by the 
# SiteNodeEngine
#
# classes that inherit from ModuleAppController can run like normal Rails controllers
# except the system will wrap the Webiva content around the controllers output, including
# support for locks and other page modifiers.
#
# The CMS site tree needs to have a valid page at the url that is set up in routes.rb
# (or the init.rb of the appropriate modules) and a "Module Application Paragraph" dropped into
# the appropriate zone.
class ModuleAppController < ApplicationController
  protect_from_forgery

  layout "page"

  skip_before_filter :context_translate_before
  skip_after_filter :context_translate_after
  skip_before_filter :check_ssl
  skip_before_filter :validate_is_editor
 
  helper :paragraph

  before_filter :handle_page
  
  after_filter :process_logging
  before_filter :validate_module
  
  include SiteNodeEngine::Controller

  def self.user_actions(names)
    self.skip_before_filter :handle_page, :only => names
    self.skip_after_filter :process_logging, :only => names
  end

  protected

  def set_title(title,*args)
    @cms_module_page_title = sprintf(title.t,*args)
  end
  
    
  def template_root
    :module
  end


  def handle_page
    process_cookie_login!

    # Handle inactive domains
    if !DomainModel.active_domain[:active] || (!myself.id && DomainModel.active_domain[:restricted])
      render :inline => "<html><head></head><body style='text-align:center'>#{DomainModel.active_domain[:inactive_message]}</body></html>"
      return false
    end

    # Handle the www issue
    if DomainModel.active_domain[:www_prefix] != @www_prefix
      dest_http = request.ssl? ? 'https://' : 'http://'

      redirect_url = dest_http +
        (DomainModel.active_domain[:www_prefix] ? 'www.' : '') +
        DomainModel.active_domain[:name] + request.request_uri

      redirect_to redirect_url, :status => '301'
      return false
    end
  
     unless params[:path]
       params[:path] = request.request_uri[1..-1].split("?")[0].split("/")
     end
      
    if params[:path][0] == 'system' 
      redirect_to "/images/spacer.gif"
      return 
    else
      @page,path_args = find_page_from_path(params[:path],DomainModel.active_domain[:site_version_id])
      @path =  params[:path].join("/")
    end

    @page = get_error_page unless @page
    
    params[:full_path] = params[:path].clone
    params[:path] = path_args


    @partial_page = params[:cms_partial_page]
    
    
    @google_analytics = Configuration.google_analytics
    
    # if we made it here - need to jump over to the application
    get_handlers(:page,:before_request).each do |req|
      cls = req[0].constantize.new(self)
      return false if(!cls.before_request)
    end    
    engine = SiteNodeEngine.new(@page,:display => session[:cms_language], :path => path_args)

    begin 
      @output = engine.run(self,myself)
    rescue SiteNodeEngine::NoActiveVersionException, SiteNodeEngine::MissingPageException => e
      display_missing_page
      return
    end

    

    # If it's a redirect, just redirect
    if @output.redirect?
      get_handlers(:page,:handle_redirect).each do |req|
        cls = req[0].constantize.new(self)
        return true if cls.handle_redirect(@output.redirect)
      end    
      redirect_to(@output.redirect, :status => 301)
      process_logging ## Need to process logging manually after doc
      return true
    # Else it's something that we have access to,
    # need to display it
    elsif @output.document?
        handle_document_node(@output,@page)
        return false
    elsif @output.page?
        set_robots!
        return true
    end 

  end
  
  def process_logging
   if Configuration.logging
    	user_agent = request.user_agent.to_s.downcase
      unless ['msnbot','yahoo! slurp','googlebot','bot','spider','crawler'].detect { |b| user_agent.include?(b) }
        # log the paragraph action if there is one
        paction = @output.paction if @output && @output.paction
        
      	if !session[:domain_log_session] || session[:domain_log_session][:end_user_id] != myself.id
      	  ses = DomainLogSession.session(request.session_options[:id] ,myself,request.remote_ip) if request.session_options
      	  session[:domain_log_session] = { :id => ses.id, :end_user_id => myself.id } if request.session_options
      	end
        DomainLogEntry.create_entry(myself,@page,@path,request.remote_ip,request.session_options[:id],@output ? @output.status : nil,paction) if request.session_options
      end
    end
  end

  def set_robots!
    @robots = []
    if @page.follow_links == 0
      @robots << 'NOFOLLOW'
    elsif @page.follow_links == 2
      @robots << 'FOLLOW'
    end
      
    if @page.index_page == 0
      @robots << 'NOINDEX'
    elsif @page.index_page == 2
      @robots << 'INDEX'
    end
    
    unless @page.cache_page?
      @robots << 'NOARCHIVE'
    end
  end
  
  def display_missing_page
    page,path_args = find_page_from_path(["404"],DomainModel.active_domain[:site_version_id])
    engine = SiteNodeEngine.new(page,:display => session[:cms_language], :path => path_args)
    @output = engine.run(self,myself)
    set_robots!
    render :template => '/page/index', :layout => 'page', :status => "404 Not Found"
    return  
  end
  
  def rescue_action_in_public(exception)
    super
    begin
      page,path_args = find_page_from_path(["500"],DomainModel.active_domain[:site_version_id])
      engine = SiteNodeEngine.new(page,:display => session[:cms_language], :path => path_args)
      @output = engine.run(self,myself)
      set_robots!
      render :template => '/page/index', :layout => 'page', :status => 500
      return  
    rescue Exception => e
      render :text => 'There was an error processing your request', :status => 500
    end
  end
  

    
  def validate_module
    info = self.class.get_component_info
    
    if !SiteModule.find_by_name_and_status(info[0],'active')
      redirect_to :controller => '/manage/access', :action => 'denied'
      return false
    else
      return true
    end
    
  end
    
  def self.component_info(name,options = {})
    options[:access] ||= :private
    options[:description] ||= ''
    
    sing = class << self; self; end
    sing.send :define_method, :get_component_info do 
      return [name,options]
    end    
  end


   
  def self.module_for(mod,name,args = {})
    modules = self.get_modules_for || []
    modules  << { :module => mod, :name => name, :options => args }
    sing = class << self; self; end
    
    sing.send :define_method, :get_modules_for do 
      modules
    end 
  end
  
  def self.get_modules_for
    []
  end

  protected
  
  def javascript_defaults
    require_js('prototype')
    require_js('user_application')
    require_js('redbox')
    require_js('scriptaculous');
    require_css('redbox');
    require_css('autocomplete');
    
    require_js('user_application')
    require_js('end_user_table')
    require_css('end_user_table')
  end  
  
  def process_cookie_login!
   if !myself.id && cookies[:remember]
    usr = EndUserCookie.use_cookie(cookies[:remember])
    if usr
      process_login(usr,true)
      usr.action("/editor/auth/cookie")
    else
      cookies[:remember] = nil
    end
   end
  end

  helper_method :webiva_post_process_paragraph
  def webiva_post_process_paragraph(txt)
    @post_process_form_token_str ||= "<input name='authenticity_token' type='hidden' value='#{ form_authenticity_token.to_s}' />"
    txt.gsub!("<CMS:AUTHENTICITY_TOKEN/>",@post_process_form_token_str)
    txt
  end
  
end
