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
  layout "page"

  skip_before_filter :context_translate_before
  skip_after_filter :context_translate_after
  skip_before_filter :check_ssl
  skip_before_filter :validate_is_editor
 
  helper :paragraph
  helper :page
  helper :module_app

  skip_before_filter :verify_authenticity_token

  before_filter :handle_page
  
  after_filter :process_logging
  before_filter :validate_module

  before_filter :nocache
  include SiteNodeEngine::Controller

  attr_accessor :visiting_end_user_id, :server_error

  hide_action :server_error, :visiting_end_user_id

  # Specifies actions that shouldn't use the CMS for authentication layout or login
  # (Often used for ajax actions)
  def self.user_actions(names)
    self.skip_before_filter :handle_page, :only => names
    self.skip_after_filter :process_logging, :only => names
  end

  protected

  # Set the title of the page 
  def set_title(title,*args)
    @cms_module_page_title = sprintf(title.t,*args)
  end
  
    
  def template_root #:nodoc:
    :module
  end

  hide_action :nocache
  def nocache
    headers['Expires'] = "Thu, 19 Nov 1981 08:52:00 GM"
    headers['Cache-Control'] =  "no-store, no-cache, must-revalidate, post-check=0, pre-check=0"
    headers['Pragma'] = "no-cache"

  end
  


  def handle_page
    process_cookie_login!

    # Handle inactive domains
    if !DomainModel.active_domain[:active] || (!myself.id && DomainModel.active_domain[:restricted])
      render :inline => "<html><head></head><body style='text-align:center'>#{DomainModel.active_domain[:inactive_message]}</body></html>"
      return false
    end

    # Handle the www issue
    unless RAILS_ENV == 'test' || RAILS_ENV == 'cucumber' # Skip ssl and domain switches in test mode
      if DomainModel.active_domain[:www_prefix] != @www_prefix
        dest_http = request.ssl? ? 'https://' : 'http://'

        redirect_url = dest_http +
          (DomainModel.active_domain[:www_prefix] ? 'www.' : '') +
          DomainModel.active_domain[:name] + request.request_uri

        redirect_to redirect_url, :status => '301'
        return false
      end
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

    return display_missing_page unless @page
    
    params[:full_path] = params[:path].clone
    params[:path] = path_args


    @partial_page = params[:cms_partial_page]
    
    
    @google_analytics = Configuration.google_analytics
    
    # if we made it here - need to jump over to the application
    get_handlers(:page,:before_request).each do |req|
      cls = req[0].constantize.new(self)
      return false unless cls.before_request
    end

    self.request_forgery_protection_token ||= :authenticity_token
    verify_authenticity_token
    
    if params['__VER__']
      @preview = true
      @revision = @page.page_revisions.find_by_identifier_hash(params['__VER__'])
      return display_missing_page unless @revision
      return render :inline => 'Invalid version' unless @revision.revision_type == 'real' || @revision.revision_type == 'temp'
    elsif @page.is_running_an_experiment?
      self.log_visitor
      if session[:domain_log_visitor]
        @revision = @page.experiment_page_revision session
      end
    end

    engine = SiteNodeEngine.new(@page,:display => session[:cms_language], :path => path_args, :revision => @revision, :preview => @preview)

    begin 
      @output = engine.run(self,myself)
    rescue SiteNodeEngine::NoActiveVersionException,ActiveRecord::RecordNotFound, SiteNodeEngine::MissingPageException => e
      display_missing_page
      return
    end

    # Add a new visitor in
    self.log_visitor

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
      begin
        handle_document_node(@output,@page)
      rescue SiteNodeEngine::NoActiveVersionException,ActiveRecord::RecordNotFound, SiteNodeEngine::MissingPageException => e
        display_missing_page
        return
      end

      return false
    elsif @output.page?
        # if we made it here - need to jump over to the application
        get_handlers(:page,:post_process).each do |req|
    	  cls = req[0].constantize.new(self)
    	  cls.post_process @output
        end
        include_stat_capture if @capture_location

        @cms_site_node_engine = engine
        set_robots!
        return true
    end 

  end


  def include_stat_capture
    @output.includes[:js] ||= []
    @output.includes[:js] << "http#{'s' if request.ssl?}://www.google.com/jsapi"
    @output.includes[:js] << "/javascripts/webalytics.js"
  end

  def log_visitor
    return if @logged_visit
    @logged_visit = true
    if Configuration.logging
      unless request.bot?
        @capture_location = DomainLogVisitor.log_visitor(cookies,myself,session,request)
        DomainLogSession.start_session(myself, session, request, @page, @capture_location)
      end
    end
  end

  def process_logging #:nodoc:
   if Configuration.logging
     unless request.bot?

       user = myself

       if session[:visiting_end_user_id]
         @visiting_end_user_id = session[:visiting_end_user_id]
         session[:visiting_end_user_id] = nil
       end

       user = self.process_visiting_user if @visiting_end_user_id

       DomainLogEntry.create_entry_from_request(user, @page, (params[:path]||[]).join('/'), request, session, @output)
     end
    end
  end

  def process_visiting_user #:nodoc:
    # if a user is logged in they are not visiting
    return myself if myself.id

    user = EndUser.find_by_id @visiting_end_user_id
    return myself unless user

    if user.elevate_user_level(EndUser::UserLevel::VISITED) && @output.respond_to?(:user_level)
      @output.user_level = EndUser::UserLevel::VISITED
    end

    if session[:domain_log_session]
      ses = DomainLogSession.find_by_id session[:domain_log_session][:id]
      if ses && ses.end_user_id.nil?
        ses.update_attribute(:end_user_id, user.id)
        ses.domain_log_visitor.update_attribute(:end_user_id, user.id) if ses.domain_log_visitor && ses.domain_log_visitor.end_user_id.nil?
      end
    end

    user
  end

  def set_robots! #:nodoc:
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

  
  def display_missing_page #:nodoc:
    page,path_args = find_page_from_path(["404"],DomainModel.active_domain[:site_version_id])
    begin
      raise SiteNodeEngine::MissingPageException.new(nil,nil) unless page
      engine = SiteNodeEngine.new(page,:display => session[:cms_language], :path => path_args)
      @output = engine.run(self,myself,:error_page => true)
      raise SiteNodeEngine::MissingPageException.new(nil,nil) unless @output.page?
      set_robots!
      render :template => '/page/index', :layout => 'page', :status => "404 Not Found"
      return  
    rescue SiteNodeEngine::MissingPageException => e
      render :text => "Page Not Found", :layout => false, :status => "404 Not Found"
      return  
    end
  end
  
  def rescue_action_in_public(exception) #:nodoc:
    super
    begin
      @server_error = exception
      @page,path_args = find_page_from_path(["500"],DomainModel.active_domain[:site_version_id])
      engine = SiteNodeEngine.new(@page,:display => session[:cms_language], :path => path_args)
      @output = engine.run(self,myself,:error_page => true)
      set_robots!
      render :template => '/page/index', :layout => 'page', :status => 500
      return  
    rescue Exception => e
      render :text => 'There was an error processing your request', :status => 500
    end
  end
  

    
  def validate_module #:nodoc:
    info = self.class.get_component_info
    
    if !SiteModule.find_by_name_and_status(info[0],'active')
      deny_access!
      return false
    else
      return true
    end
    
  end
    
  # Specifies the component that this controller is a part of.
  # Only the admin controller needs to specify the additional options
  #
  # ===Options
  # [:access]
  #   :public, :private or :hidden. :public modules are available to all domains, :private modules
  #   need to be made available from System Domains while :hidden modules must be activated directly
  #   via the DB.
  # [:description]
  #   Description of this module that appears on the options => modules page
  def self.component_info(name,options = {})
    options[:access] ||= :private
    options[:description] ||= ''
    
    sing = class << self; self; end
    sing.send :define_method, :get_component_info do 
      return [name,options]
    end    
  end


  # Register a named site module (draggable onto the site from the structure page)
  def self.module_for(mod,name,args = {})
    modules = self.get_modules_for || []
    modules  << { :module => mod, :name => name, :options => args }
    sing = class << self; self; end
    
    sing.send :define_method, :get_modules_for do 
      modules
    end 
  end
  
  def self.get_modules_for #:nodoc:
    []
  end

  protected
  
  # Includes all the standard Webiva/rails front-end javascripts 
  # prototype, user_application, redbox, scriptaculous, end_user_table
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
  
  def process_cookie_login! #:nodoc:
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
