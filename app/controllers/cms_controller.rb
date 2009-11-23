# Copyright (C) 2009 Pascal Rettig.

# Parent class for all Webiva backend controllers. All controllers which 
# expose backend functionality should inherit from this class (or one of it's children)
class CmsController < ApplicationController
     
  layout 'manage'

  include SiteAuthorizationEngine::Controller
  include ActiveTable::Controller

  before_filter :validate_is_editor
  
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
    if myself && myself.user_class
      myself.user_class.editor?
    else
      store_return_location
      redirect_to :controller => '/manage/access', :action => 'denied'
    end
  end

  # Generate friendlier error messages than the 500-white-screen-of-death
  def rescue_action_in_public(exception)
    begin
      if !@cms_page_info
        cms_page_info ["Error"]
      end
      if exception.is_a?(ActiveRecord::RecordNotFound)
        @error_message = "The record you were looking for could not be found"
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



end
