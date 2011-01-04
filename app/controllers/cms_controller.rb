# Copyright (C) 2009 Pascal Rettig.

# Parent class for all Webiva backend controllers. All controllers which 
# expose backend functionality should inherit from this class (or one of it's children)
#
# 
class CmsController < ApplicationController
     
  layout 'manage'

  include SiteAuthorizationEngine::Controller
  include ActiveTable::Controller

  before_filter :validate_is_editor

  before_filter :generate_menu

  hide_action :active_table_action, :active_table_generate, :auto_link, :concat, :current_cycle, :cycle
  hide_action :excerpt, :highlight, :markdown, :permit, :permit?, :pluralize, :reset_cycle, :simple_format, :textilize
  hide_action :textilize_without_paragraph, :truncate, :word_wrap
  
  protected

  # Store the current location in case of a lockout
  # can be used by renderers to allow redirection back after 
  # registration or login
  def store_return_location 
    session[:lockout_current_url] = self.request.path_info
  end
  
  # Filter method validating that the current user has an
  # editor user class. Skip this filters to get around the requirement.
  def validate_is_editor
    if myself.id && myself.user_class
      if !myself.user_class.editor?
        redirect_to :controller => '/manage/access', :action => 'denied'
      end
    else
      store_return_location
      redirect_to :controller => '/manage/access', :action => 'denied'
    end

    if params[:return_to_site] 
      url = request.referer.to_s.gsub!(/^https?\:\/\/[^\/]+/,"")
      unless url.blank? || url =~ /^\/website/
        session[:return_to_site] = url
      end
    end

    if session[:return_to_site]
      @cms_return_to_site_url = session[:return_to_site]
    end

    @cms_titlebar_handlers = get_handler_instances(:webiva,:titlebar,self)
  end

  def generate_menu
    if !request.xhr?
      @menu = WebivaMenu.new do |menu|
        menu.item(0,'website', ['editor_website','editor_structure'], :controller => '/structure')
        menu.item(10,'content',nil,:controller => '/content')
        menu.item(20,'files',['editor_files'],:controller => '/file')
        menu.item(30,'people',['editor_members'],:controller => '/members')
        menu.item(40,'marketing',['editor_visitors'],:controller => '/emarketing')
        menu.item(50,'mail',['editor_mailing'],:controller => '/mail_manager')
        menu.item(60,'options',['editor_design_templates','editor_permissions','editor_site_management','editor_editors','editor_emails'],:controller => '/options')
        menu.item(100,'system',['system_admin','client_admin'],:controller => '/manage/system') 
      end

      get_handler_instances(:webiva,:titlebar,self)


      @menu.authorize(myself)
    end

    true
  end


  # Generate friendlier error messages than the 500-white-screen-of-death
  def rescue_action_in_public(exception)
    begin
      if !@cms_page_info
        cms_page_info ["Error"]
      end
      if exception.is_a?(ActiveRecord::RecordNotFound)
        @error_message = "The record you were looking for could not be found"
      elsif exception.is_a?(ActionController::InvalidAuthenticityToken)
        @error_message = 'The form you submitted expired, reloading page'
        headers['Refresh'] = '3; URL=' + request.url
      else
        super
        @error_message = 'There was a problem processing your request'
        @review = true
      end
      if request.xhr?
        render :string => "<div class='error'>#{@error_message}</div>"
      else
        render :template => '/application/error', :layout => 'manage'
      end
    rescue Exception => e
      render :text => 'There was an error processing your request', :status => 500
    end
  end
  
     

   def self.get_content_info # :nodoc:
      []
   end
  
   # Register a content model to appear on the content
   # This controller must define a class method called
   # self.get_[:name:]_info which 
   def self.content_model(name,options = {})
      content = self.get_content_info
      content << [ name,options ]
      sing = class << self; self; end
      sing.send :define_method, :get_content_info do 
        return content
      end    
      
   end

  def self.get_content_actions # :nodoc:
    []
  end

  # Register a content action to appear in the action panel on the content page
  #
  # For example:
  #
  #  content_action  'Create a new Blog', { :controller => '/blog/admin', :action => 'create' }, :permit => 'blog_config'
  #
  # Will add an action to called 'Create a new Blog' to the top of the content page that will be visible only
  # to users with the blog_config permission
  def self.content_action(action,url,options = {})
    actions = self.get_content_actions
    actions << [ action, url, options ]
      sing = class << self; self; end
      sing.send :define_method, :get_content_actions do 
        return actions
      end    
  end

  def self.get_content_models_and_actions # :nodoc:
      content_models = []
      content_actions = []
      Dir.glob("#{RAILS_ROOT}/app/controllers/editor/[a-z0-9\-_]*_controller.rb") do |file|
        if file =~ /\/([a-z0-9\-_]+)_controller.rb$/
          controller_name = $1
          if controller_name != 'admin'
            cls = "Editor::#{controller_name.camelcase}Controller".constantize
            if(cls.respond_to?('get_content_info')) 
               cls.get_content_info.each do |content_model|
                  active_models = cls.send("get_#{content_model[0]}_info")
                  content_models += active_models
               end
            end
            if(cls.respond_to?('get_content_actions')) 
               content_actions += cls.get_content_actions
            end
          end
        end
      end
      SiteModule.enabled_modules_info.each do |mod|
        cls = mod.admin_controller_class
        if(cls.respond_to?('get_content_info')) 
          cls.get_content_info.each do |content_model|
            active_models = cls.send("get_#{content_model[0]}_info")
            content_models += active_models
          end
        end
        if(cls.respond_to?('get_content_actions')) 
            content_actions += cls.get_content_actions
        end
      end
      
      [ content_models, content_actions ]
    end

  # Register a new permission category, which coresponds
  # to a new tab in the permissions list. Should only be used in AdminControllers
  #
  # Usage:
  #
  #   register_permission_category :category_type, "Humane Name" ,"Short Descriptions"
  #
  # for example:
  #
  #   register_permission_category :blog, "Blog" ,"Permissions for Writing Blogs"
  #
  # Will cause a new tab to appear in permissions called blog
  #
  def self.register_permission_category(category,name,desc)
    
    cats = self.registered_permission_categories;
    cats += [ category, name, desc ]
    
    sing = class << self; self; end
    sing.send :define_method, :registered_permission_categories do 
      return cats
    end    
  end
  
  # Register a set of permissions for a module should be only called from AdminController
  #
  # Accepts a category name, and a list of permissions in the following format:
  #        [ [ :perm_1, "Perm 1 Name", "Perm 1 Description" ],
  #          [ :perm_2, "Perm 2 Name", "Perm 2 Description" ] ]
  #
  # Example
  #
  #    register_permissions :blog, [ [ :config, 'Blog Configure', 'Can Configure Blogs'],
  #                              [ :writer, 'Blog Writer', 'Can Write Blogs'],
  #                              [ :user_blogs, 'User Blog Editor', 'Can Edit User Blogs' ]
  #                           ]
  #
  # When they are used in the system, all permissions are reference with their category, so this 
  # registers 3 permissions inside the blog category called :blog_config, :blog_writer, 
  # and :blog_user_blogs.
  #
  # Permissions can be used at the class level (inside cms_controllers), by adding class level
  # permit calls, e.g.:
  #
  #      permit :blog_config
  #
  # Will prevent access to any pages of that controller unless the user has the blog_config permission
  # in their profile or in an access token.
  #
  # Permissions can also be accessed directly on user objects, for example:
  #      
  #      if myself.has_role?(:blog_writer) 
  #          ... Stuff only blog writers can do or see ...
  #      end
  #
  def self.register_permissions(cat,new_permissions)
    perms = self.registered_permissions;
    
    perms[cat] ||= []
    perms[cat] += new_permissions
    
    sing = class << self; self; end
    sing.send :define_method, :registered_permissions do 
      perms
    end    
  end
  
  def self.registered_permissions # :nodoc
    {}
  end

  def self.registered_permission_categories # :nodoc:
    []
  end


  # Deprecated in favor of cms_page_paths
  def cms_page_info(title,section=nil,menu_js = nil) # :nodoc:
    @cms_page_info = { :title => title, 
      :section => section,
      :menu_js => menu_js }
    
    if title.is_a?(Array)
      if title.last.is_a?(Array)
        title_info = title.last
        if(title_info .length > 2)
          page_title = sprintf(title_info [0].t,*title_info [2..-1])
        else
          page_title = title_info[0].t
        end
      else
        page_title = title.last.t
      end
    else
      page_title=title.t
    end
    
    title = Configuration.options.domain_title_name || "CMS"
    @cms_page_info[:page_title] = title.to_s + ": " +  page_title.to_s
  end
  
  # Class level method that registers admin paths into the controller
  # by default the Options and Content paths are available.
  # 
  # The section argument defines the tab that a this controller appears in
  # while pages is a hash consisting of human page names as keys and 
  # a url_for arguments hash as a value
  # 
  #      "Human Page Name" => { :action => 'page_action' },
  #      "Human Page Name 2" => { :controller => "other_controller", :action => "other action" }
  #
  # These can be used in controller methods by calling cms_page_path, for example:
  # 
  #     def method_name
  #       cms_page_path [ "Content", "Human Page Name" ], "Current Page Title" 
  #       ...
  #
  # The last page title does not need to exist in cms_admin_paths unless it 
  # is referenced somewhere else in the controller.
  def self.cms_admin_paths(section,pages = {})
    pages['Content'] ||= { :controller => '/content' } 
    pages['Website'] ||= { :controller => '/structure' }
    pages['Options'] ||= { :controller => '/options' }
    pages['Modules'] ||= { :controller => '/modules' }
    sing = class << self; self; end
    sing.send :define_method, "cms_page_path_info" do
      { :section => section, :pages => pages }
    end
  end

  # Sets the current page title and breadcrumbs 
  # in each controller method
  def cms_page_path(pages,info,menu_js=nil,section=nil)
    ap = self.class.cms_page_path_info
    output_pages = []
    pages.each do |page_name|
      if page_name.is_a?(Array)
        output_pages << page_name
      else
        raise 'Invalid Page:' + page_name unless ap[:pages][page_name]
        opts = ap[:pages][page_name].clone
        output_pages << [ page_name,cms_page_url_from_opts(opts)  ]
      end
    end

    output_pages << info
    cms_page_info(output_pages,section || ap[:section],menu_js)
  end
  
  # Redirects to another page defined in cms_admin_paths
  def cms_page_redirect(page_name)
     ap = self.class.cms_page_path_info
     page = ap[:pages][page_name]

     raise 'Invalid cms_page_direct:' + page_name unless page
     redirect_to cms_page_url_from_opts(page.clone)
  end

  private 

  def cms_page_url_from_opts(opts) #:nodoc:
    ctrler = opts.delete(:controller)
    act = opts.delete(:action)
    url_hash = {}
    url_hash[:controller] = ctrler if ctrler
    url_hash[:action] = act if act
    opts.each do |key,val|
      url_hash[key] = params[val]
    end
    url_for(url_hash)
  end
  




end
