# Copyright (C) 2009 Pascal Rettig.

require "yaml"
require 'singleton'
require 'pp'

# Parent controller class for all Webiva Controllers
# However
class ApplicationController < ActionController::Base 
   protect_from_forgery
   filter_parameter_logging :payment, :contribute
  
  @@domains = {}
  
  

  helper_method :current_user
  helper_method :myself
  helper_method :my_access
  helper_method :page_editor?

  hide_action :get_handler_instance, :get_handler_instances, :get_handler_options, :get_handler_values, :get_handlers, :h, :vh, :tag
  hide_action :auto_discovery_link_tag, :cdata_section, :content_tag, :escape_once, :get_handler_info
  hide_action :image_path, :image_tag, :javascript_include_tag, :javascript_path, :jvh, :path_to_image, :path_to_javascript
  hide_action :path_to_stylesheet, :render_output, :stylesheet_link_tag, :stylesheet_path
  
  
  before_filter :check_ssl
  prepend_before_filter :activate_domain
  append_after_filter :clear_cache



  after_filter :save_anonymous_tags
  
  hide_action :myself

  # Returns an EndUser object representing the currently logged in user
  # Anonymous users still return an EndUser object except with a special user class
  # and without a valid ID
  #
  # The user object is cached in the response object so it is only generated once
  # per request
  def myself
    return EndUser.default_user unless response
    if response.data[:user]
      if response.data[:user].is_a?(ClientUser) 
        return response.data[:end_user]
      else
        return response.data[:user]
      end
    end

    session[:user_tracking] ||= {}

    if session[:user_id].blank? || session[:user_model].blank? 
      response.data[:user] = EndUser.default_user 
      response.data[:user].anonymous_tracking_information = session[:user_tracking]
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

  hide_action :theme_src
  helper_method :theme_src
  # Returns a relative link for an image using the currently active theme
  def theme_src(img=nil) 
    if img.to_s[0..6] == "/images"
      "/themes/#{theme}" + img.to_s
    else
      "/themes/#{theme}/images/" + img.to_s
    end
  end
  
  hide_action :url_for
  # Override method to convert path into an array if necessary
  def url_for(opts = {}) # :nodoc: 
    if(opts.is_a?(Hash) && opts[:path] && !opts[:path].is_a?(Array)) 
      if opts[:path].blank?
        opts.delete(:path)
      else
        opts[:path] = [ opts[:path] ]
      end
    end
    opts.delete(:path) if opts[:path] && opts[:path] == [ nil ]
    super
  end

  


  protected

  # Checks if a parameter exists in parms, then the session, otherwise sets it to the
  # default value, sets the session and returns the value
  #
  # Used primarily for toggles on the backend (like archived in structure)
  def handle_session_parameter(parameter_name,default_val = nil,options = {})

    parameter_name = parameter_name.to_sym
    # Show return to be explicit what we are doing (setting session value & returning)
    if params.has_key?(parameter_name)
      return session[parameter_name] = params[parameter_name]
    else
      return session[parameter_name] || default_val
    end
  end

  def clear_cache #:nodoc:
    DataCache.reset_local_cache
  end
  
  def template_root #:nodoc:
    :application
  end
  
  # Helper method to sanitize html
  def sanitize(html,options={})
    @html_sanitizer ||= HTML::Sanitizer.new
    
    @html_sanitizer.sanitize(html,options)
  end
  
  # Helper method to strip all tags from any html
  def strip_tags(html,options={})
    @full_sanitizer ||= HTML::FullSanitizer.new
    
    @full_sanitizer.sanitize(html)
  end
  
  
  def save_anonymous_tags #:nodoc:
    if !session[:user_id] 
      session[:user_tracking] = myself.anonymous_tracking_information
    else 
      session.delete(:user_tracking)
    end
    
  end
  
  def check_ssl #:nodoc:
    if @cms_domain_info  && @cms_domain_info[:ssl_enabled] && !request.ssl?
      redirect_to  'https://' + request.domain(10) + request.request_uri
      return false
    end
  end

  # Helper method to tell the browser not to cache a page
  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  # helper method to redirect a user to the access denied page
  # call from a controller method with :
  #
  #    return deny_access!
  #
  def deny_access!
    redirect_to :controller => '/manage/access', :action => 'denied'
  end
  
  # Activate the appropriate database for the current request
  def activate_domain(domain=nil)
    
    # Cancel out of domain activations
    # if we are testing
    if RAILS_ENV == 'test' || RAILS_ENV == 'cucumber' || RAILS_ENV == 'selenium'
      DomainModel.activate_domain(Domain.find(CMS_DEFAULTS['testing_domain']).get_info,'production',false)
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

    response.headers['P3P'] = 'CP="IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT"'


    # Skip for the the PublicController to prevent touching the session and 
    # sending back a session cookie
    # Protect against using a session from a different
    # domain on this domain 
    # also log users out of if the domain has it's version modified
    if session[:domain] &&  session[:domain] != domain || session[:domain_version] != dmn_info[:iteration]
      process_logout
    end

    session[:domain_version] = dmn_info[:iteration]
    session[:domain] = domain

    set_language

    set_timezone
        
    return true
  end

  def set_timezone
    Time.zone  = myself.time_zone.blank? ? Configuration.time_zone : myself.time_zone
  end


  def set_language #:nodoc:
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

  @@ignored_session_keys = [:domain, :cms_language, :domain_version]
  def session_safe_clear
    session.delete_if do |k,v|
      ! @@ignored_session_keys.include?(k)
    end
  end

  # Convenience method to log a user in 
  # sets the session and remember cookie 
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
  
  # Convenience method to log a user out
  def process_logout
    EndUserCookie.kill_user_cookies(myself)
    session[:user_id] = nil
    session[:user_model] = nil
    reset_myself
    session_safe_clear
    myself
  end
  
  # Convenience method to check whether a user can edit pages
  def page_editor?
    usr = myself
    usr.id && usr.editor? && usr.has_role?('editor_editor')
  end
  

  # Returns a piece of domain configuration
  # Caching config in the response
  def domain_config(key)
    Configuration.options.send(key)
  end  

  helper_method :theme
  # Returns the current theme
  def theme
    return response.data[:theme] if response.data[:theme]
    return response.data[:theme] = (domain_config('theme') || 'standard')
  end


  # Resets the cached myself object to allow a user change
  def reset_myself
    response.data[:user] = nil
  end
  
  
  
  hide_action :denied_access
  hide_action :override_client
  
  before_filter :context_translate_before
  after_filter :context_translate_after
  after_filter :set_cset
  
  def set_cset #:nodoc:
    headers['Content-Type'] ||= 'text/html'
    if headers['Content-Type'].starts_with?('text/') and !headers['Content-Type'].include?('charset=')
      headers['Content-Type'] += '; charset=utf-8'
    end
  end
  
  def context_translate_before #:nodoc:
    
    if session[:context_translation] && permit?('translator')
      Locale.save_requests
    end
  end
  
  def context_translate_after #:nodoc:
    if session[:context_translation] && permit?('translator')
      session[:context_translation_requests] = Locale.retrieve_requests
    end
  end
  
  def denied_access #:nodoc:
    flash[:notice] = "Access Denied"

    redirect_to(:controller => "/manage/access", :action => "login")
  end

  def debug_raise(obj) # :nodoc:
    raise render_to_string(:inline =>  '<%= debug object -%>', :locals => { :object => obj})
  end

  helper_method :active_module?
  # Check if a specific module is activted
  def active_module?(mod) 
    response.data[:modules] ||= {}
    return response.data[:modules][mod] if response.data[:modules].has_key?(mod)
    md = SiteModule.find_by_name_and_status(mod,'active')
    response.data[:modules][mod] = md ? true : false
  end
  
  # Expires a the cache of a site completely (including all content)
  def expire_site
    DataCache.expire_site
  end
  
  
  include HandlerActions
  
  helper_method :get_handler_info

  helper_method :debug_print
  def debug_print(*obj) # :nodoc:
    render :inline => "<%= debug obj %>", :locals => {:obj => obj }
  end


  
  def rescue_action_in_public(exception,display = true) # :nodoc:
    return  render(:text => 'Page not found', :status => :not_found) if exception.is_a?(ActionController::RoutingError)
    return if exception.is_a?(ActionController::InvalidAuthenticityToken)

    deliverer = self.class.read_inheritable_attribute(:exception_data)
    data = case deliverer
           when nil then {}
           when Symbol then send(deliverer)
           when Proc then deliverer.call(self)
           end
    
    btrace = sanitize_backtrace(exception.backtrace)

     
    error_data = render_to_string :partial => 'application/backtrace', 
    :locals => { 
      :controller => self, 
      :parameters => filter_parameters(request.parameters),
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
  
  # include a js file in the html header
  def require_js(js)
    js += ".js" unless js[-3..-1] == '.js'
    @js_header ||= []
    
    @js_header << js
  end  

  # include a CSS file in the html header
  def require_css(css)
    @css_header ||= []
    @css_header << css
  end
  
  # Add some additional html to header
  def header_html(html)
    @extra_header ||= []
    @extra_header << html
  end
  
  include EscapeMethods

  # Handles a front-end file upload by turning an uploaded file into a domain file id
  def handle_file_upload(parameters,key,options = {}) 
    
    if !parameters[key].to_s.empty? && DomainFile.available_file_storage > 0
      image_folder  = options[:folder] || Configuration.options.default_image_location
      file = DomainFile.create(:filename => parameters[key],
                               :parent_id => image_folder,
                               :creator_id => myself.id,
                               :process_immediately => true)
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
  
  # Handles a front-end file upload by turning an uploaded file into an image.
  # other file types are not accepted.
  def handle_image_upload(parameters,key,options = {}) 
    
    if parameters[key.to_s + "_clear"].to_s == '0'
      parameters[key] = nil
    elsif !parameters[key].to_s.empty? && DomainFile.available_file_storage > 0
      image_folder  = options[:folder] || Configuration.options.default_image_location
      file = DomainFile.create(:filename => parameters[key],
                               :parent_id => image_folder,
                               :creator_id => myself.id,
                               :process_immediately => true)
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

  def send_domain_file(df, opts={})
    df = DomainFile.find_by_id(df) if df.is_a?(Integer)
    return false unless df

    df.filename # copy locally
    return false unless File.exists?(df.filename)

    opts[:stream] = true unless opts.key?(:stream)
    opts[:type] ||= df.mime_type
    opts[:disposition] ||= 'attachment'
    opts[:filename] ||= df.name

    send_file(df.filename, opts)
    true
  end

  private

  def sanitize_backtrace(trace) # :nodoc:
    re = Regexp.new(/^#{Regexp.escape(rails_root)}/)
    trace.map { |line| Pathname.new(line.gsub(re, "[RAILS_ROOT]")).cleanpath.to_s }
  end

  def rails_root # :nodoc:
    return @rails_root if @rails_root
    @rails_root = Pathname.new(RAILS_ROOT).cleanpath.to_s
  end  

end
