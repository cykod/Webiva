# Copyright (C) 2009 Pascal Rettig.


require 'singleton' 

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

  before_filter :nocache
  include SiteNodeEngine::Controller

  def self.user_actions(names)
    self.skip_before_filter :handle_page, :only => names
    self.skip_after_filter :process_logging, :only => names
  end

  hide_action :set_title
  def set_title(title,*args)
    @cms_module_page_title = sprintf(title.t,*args)
  end
  
    
  hide_action :template_root
  def template_root
    :module
  end

  hide_action :nocache

  def nocache
    headers['Expires'] = "Thu, 19 Nov 1981 08:52:00 GM"
    headers['Cache-Control'] =  "no-store, no-cache, must-revalidate, post-check=0, pre-check=0"
    headers['Pragma'] = "no-cache"

  end
  


  hide_action :handle_page
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

    set_language

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

  hide_action :set_robots
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
  
  
  def set_language
    # Setup language handling
    domain_languages = Configuration.languages
    
    client_accept_language = nil
    # Check if there is a user requested language
    if(!session[:cms_language] && request.env['HTTP_ACCEPT_LANGUAGE']) 
      # Check languages by order of importance
      langs = request.env['HTTP_ACCEPT_LANGUAGE'].split(",")
      langs.each do |lang|
        # get just the language, ignore the locale
        lang = lang[0..1]
        if domain_languages.include?(lang)
          client_accept_language = lang
          break
        end
      end
    
    end
    
    
    session[:cms_language] ||= client_accept_language || domain_languages[0]
    
    if(params[:set_language] && domain_languages.include?(params[:set_language]))
      session[:cms_language] = params[:set_language]
    end
    
    Locale.set(session[:cms_language]) unless RAILS_ENV == 'test'
    
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
  
end
