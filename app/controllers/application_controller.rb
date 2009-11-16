# Copyright (C) 2009 Pascal Rettig.

require "yaml"
require 'singleton'
require 'pp'


# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base 
   protect_from_forgery
  
  
  @@domains = {}
  
  

  helper_method :current_user
  helper_method :myself
  helper_method :my_access
  helper_method :page_editor?
  
  
  before_filter :check_ssl
  prepend_before_filter :activate_domain
  append_after_filter :clear_cache



  after_filter :save_anonymous_tags
  
  hide_action :myself
  def myself
    if response.data[:user]
      if response.data[:user].is_a?(ClientUser) 
        return response.data[:end_user]
      else
        return response.data[:user]
      end
    end
    
    if session[:user_id].blank? || session[:user_model].blank? 
      response.data[:user] = EndUser.default_user 
      response.data[:user].tag_names_add(session[:user_tags]) if session[:user_tags]
      response.data[:user].referrer = session[:user_referrer] if session[:user_referrer]
    else
      begin
        userModel = session[:user_model].constantize
        response.data[:user] = userModel.find_by_id(session[:user_id]) if userModel && !session[:user_model].blank?
      rescue Exception => e
        response.data[:user] = EndUser.default_user         
      end

      response.data[:user] ||= EndUser.default_user 
    end
    if(response.data[:user].is_a?(ClientUser))
      response.data[:end_user] ||= response.data[:user].end_user
      response.data[:end_user]
    else
      response.data[:user]
    end
    
  end   
  

  helper_method :theme_src
  def theme_src(img=nil) 
    if img.to_s[0..6] == "/images"
      "/themes/#{theme}" + img.to_s
    else
      "/themes/#{theme}/images/" + img.to_s
    end
  end
  
  def url_for(opts = {})
    if(opts.is_a?(Hash) && opts[:path] && !opts[:path].is_a?(Array)) 
      if opts[:path].blank?
        opts.delete(:path)
      else
        opts[:path] = [ opts[:path] ]
      end
    end
    super
  end

  


  protected

  def clear_cache
    classes = (DataCache.local_cache("content_models_list") || {}).values
    classes.each do |cls|
     Object.send(:remove_const,cls[1]) if Object.const_defined?(cls[1])
    end
    classes = {}
    
    DataCache.reset_local_cache
#    ContentModelType.remove_subclasses
    ContentModelType.subclasses
  end
  
  def template_root
    :application
  end
  
  def sanitize(html,options={})
    @html_sanitizer ||= HTML::Sanitizer.new
    
    @html_sanitizer.sanitize(html,options)
  end
  
  def strip_tags(html,options={})
    @full_sanitizer ||= HTML::FullSanitizer.new
    
    @full_sanitizer.sanitize(html)
  end
  
  
  def save_anonymous_tags
    if !session[:user_id] 
      session[:user_tags] = myself.tag_cache unless myself.tag_cache.blank?
      session[:user_referrer] = myself.referrer unless myself.referrer.blank?
    else 
      session[:user_tags] = nil
      session[:user_referrer] = nil
    end
    
  end
  
  def check_ssl
    if @cms_domain_info  && @cms_domain_info[:ssl_enabled] && !request.ssl?
      redirect_to  'https://' + request.domain(10) + request.request_uri
      return false
    end
  end

  def deny_access!
    redirect_to :controller => '/manage/access', :action => 'denied'
  end
  
  def activate_domain(domain=nil)
    
    # Cancel out of domain activations
    # if we are testing
    if RAILS_ENV == 'test'
      return true
    else 
      domain = request.domain(5)
      if domain =~ /^www\.(.*)/
        @www_prefix = true
        domain = $1
      else
        @www_prefix = false
      end
    end

 
    dmn_info = Configuration.fetch_domain_configuration(domain)

    # No domain - invalid
    if !dmn_info
      render :text => 'Invalid Domain'
      return false
    # otherwise we could be a redirect
    elsif dmn_info.is_a?(String)
      redirect_to dmn_info
      return false
    end
    

    
    # Activate the correct DB connection
    unless DomainModel.activate_domain(dmn_info,'production')
      raise 'Invalid Domain Info:' + dmn_info[:name]
      return false
    end
    
    @cms_domain_info = dmn_info
    
    # Protect against using a session from a different
    # domain on this domain
    if session[:domain] &&  session[:domain] != domain
      session.delete()
    end
    
    session[:domain] = domain
    
    unless session[:cms_language]
      session[:cms_language] = Configuration.languages[0]    
    end
    
    Locale.set(session[:cms_language])
    
    return true
  end
  
  def current_user 
    myself.user_profile
  end
  
  def my_access
    myself.user_profile
  end
  
  def process_login(usr,remember = false)
    session[:user_id] = usr.id
    session[:user_model] = usr.class.to_s
    reset_myself
    myself
    if remember
      remember_time = 2.week.from_now
      cookies[:remember] = { :value => EndUserCookie.generate_cookie(usr,remember_time), :expires => remember_time }
    end
  end
  
  def process_logout
    EndUserCookie.kill_user_cookies(myself)
    session[:user_id] = nil
    session[:user_model] = nil
    reset_myself
    myself
    session = {}
  end
  
  def page_editor?
    usr = myself
    usr.id && usr.editor? && usr.has_role?('editor_editor')
  end
  


  def domain_config(key)
    if response.data[:config]
      return response.data[:config][key]
    else
      response.data[:config] = Configuration.get('options')
      return response.data[:config][key]
    end
  end  

  helper_method :theme
  def theme
    return response.data[:theme] if response.data[:theme]
    return response.data[:theme] = (domain_config('theme') || 'standard')
  end




  def reset_myself
    response.data[:user] = nil
  end
  
  
  
  hide_action :denied_access
  hide_action :verify_site_access
  hide_action :override_client
  
  before_filter :context_translate_before
  after_filter :context_translate_after
  after_filter :set_cset
  
  def set_cset
    headers['Content-Type'] ||= 'text/html'
    if headers['Content-Type'].starts_with?('text/') and !headers['Content-Type'].include?('charset=')
      headers['Content-Type'] += '; charset=utf-8'
    end
  end
  
  def context_translate_before
    
    if session[:context_translation] && permit?('translator')
      Locale.save_requests
    end
  end
  
  def context_translate_after
    if session[:context_translation] && permit?('translator')
      session[:context_translation_requests] = Locale.retrieve_requests
    end
  end
  
  def denied_access
    flash[:notice] = "Access Denied"

    redirect_to(:controller => "/manage/access", :action => "login")
  end

  include SimpleCaptcha::ControllerHelpers

  def self.register_permission_category(type,name,desc)
    
    cats = self.registered_permission_categories;
    cats += [ type, name, desc ]
    
    sing = class << self; self; end
    sing.send :define_method, :registered_permission_categories do 
      return cats
    end    
  end
  
  def self.register_permissions(cat,new_permissions)
    perms = self.registered_permissions;
    
    perms[cat] ||= []
    perms[cat] += new_permissions
    
    sing = class << self; self; end
    sing.send :define_method, :registered_permissions do 
      perms
    end    
  end
  
  def self.registered_permissions; {}; end;
  def self.registered_permission_categories; []; end
  
  def verify_site_access
    #raise request.env['SERVER_NAME']
  end

  def cms_page_info(title,section=nil,menu_js = nil)
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
  
  def self.cms_admin_paths(section,pages = {})
    pages['Content'] ||= { :controller => '/content' }
    pages['Options'] ||= { :controller => '/options' }
    sing = class << self; self; end
    sing.send :define_method, "cms_page_path_info" do
      { :section => section, :pages => pages }
    end
  end
  
  
  def cms_css(css)
    @header ||= ''
    @header += "<link href='#{css}' media='screen' rel='stylesheet' type='text/css' />\n"
  end
  
  def cms_js(js)
    @header ||= ''
    @header += "<script src='#{js}' type='text/javascript'></script>\n"
  end
  
  private 
  def cms_page_url_from_opts(opts)
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
  
  
  def handle_session_parameter(parameter_name,default_val = nil,options = {})

    parameter_name = parameter_name.to_sym
    # Show return to be explicit what we are doing (setting session value & returning)
    if params.has_key?(parameter_name)
      return session[parameter_name] = params[parameter_name]
    else
      return session[parameter_name] || default_val
    end
  end
  
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
  
  def cms_page_redirect(page_name)
    ap = self.class.cms_page_path_info
    page = ap[:pages][page_name]
    
    raise 'Invalid cms_page_direct:' + page_name unless page
    redirect_to cms_page_url_from_opts(page.clone)
  end
  
  def debug_raise(obj)
    raise render_to_string(:inline =>  '<%= debug object -%>', :locals => { :object => obj})
  end

  helper_method :active_module?
  def active_module?(mod)
    response.data[:modules] ||= {}
    return response.data[:modules][mod] if response.data[:modules].has_key?(mod)
    md = SiteModule.find_by_name_and_status(mod,'active')
    response.data[:modules][mod] = md ? true : false
  end
  
  def expire_site
    DataCache.expire_container('SiteNode')
    DataCache.expire_container('Handlers')
    DataCache.expire_container('SiteNodeModifier')
    DataCache.expire_container('Modules')
    DataCache.expire_content
  end
  
  
  include HandlerActions
  
  helper_method :get_handler_info

  #  def local_request?
  #    false
  #  end

  helper_method :debug_print
  def debug_print(*obj)
    render :inline => "<%= debug obj %>", :locals => {:obj => obj }
  end


  
  def rescue_action_in_public(exception,display = true)
    
    deliverer = self.class.read_inheritable_attribute(:exception_data)
    data = case deliverer
           when nil then {}
           when Symbol then send(deliverer)
           when Proc then deliverer.call(self)
           end
    
    btrace = sanitize_backtrace(exception.backtrace)
    
    error_data = render_to_string :partial => '/application/backtrace', 
    :locals => { 
      :controller => self, 
      :request => request,
      :exception => exception, 
      :host => request.env["HTTP_HOST"],
      :backtrace => btrace,
      :rails_root => rails_root, 
      :data => data
    }
    
    
    if self.class.to_s == 'PageController'
      location = 'site:'
    else 
      location = 'cms:'
    end
    error_location= "#{self.controller_name}##{self.action_name}"
    parent_issue = SystemIssue.register_child!(btrace.first,error_location,exception.class.to_s )
    
    issue = SystemIssue.create(:reported_at => Time.now,
                               :reporting_domain => DomainModel.active_domain_name,
                               :reporter_user => myself,
                               :status => 'reported',
                               :reported_type => 'auto',
                               :location => location + request.request_uri,
                               :behavior => error_data,
                               :code_location => btrace.first,
                               :error_type => exception.class.to_s,
                               :error_location => error_location,
                               :parent_id => parent_issue ? parent_issue.id : nil )
  end
  
  
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::TagHelper
  
  def require_js(js)
    js += ".js" unless js[-3..-1] == '.js'
    @js_header ||= []
    
    @js_header << js
  end  

  def require_css(css)
    @css_header ||= []
    @css_header << css
  end
  
  def header_html(html)
    @extra_header ||= []
    @extra_header << html
  end
  
  include EscapeMethods

  def handle_file_upload(parameters,key,options = {}) 
    
    if !parameters[key].to_s.empty?
      image_folder  = options[:folder] || Configuration.options.default_image_location
      file = DomainFile.create(:skip_transform => true,:filename => parameters[key],:parent_id => image_folder,:creator_id => myself.id )
      if file.id
        parameters[key] = file.id 
      else
        parameters.delete(key)
        file.destroy
      end
    else
      parameters.delete(key)
    end

  end
  
  def handle_image_upload(parameters,key,options = {}) 
    
    if parameters[key.to_s + "_clear"].to_s == '0'
      parameters[key] = nil
    elsif !parameters[key].to_s.empty?
      image_folder  = options[:folder] || Configuration.options.default_image_location
      file = DomainFile.create(:filename => parameters[key],
                               :parent_id => image_folder,
                               :creator_id => myself.id)
      if file.file_type == 'img'
        parameters[key] = file.id
      else
        parameters.delete(key)
        file.destroy
      end
    else
      parameters.delete(key)
    end  
    parameters.delete(key.to_s + "_clear")
  end 
  
  private

  def sanitize_backtrace(trace)
    re = Regexp.new(/^#{Regexp.escape(rails_root)}/)
    trace.map { |line| Pathname.new(line.gsub(re, "[RAILS_ROOT]")).cleanpath.to_s }
  end

  def rails_root
    return @rails_root if @rails_root
    @rails_root = Pathname.new(RAILS_ROOT).cleanpath.to_s
  end  
  
end
