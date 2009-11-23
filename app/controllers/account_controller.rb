# Copyright (C) 2009 Pascal Rettig.

class AccountController < CmsController # :nodoc: all
  layout 'manage'

  def index
  
    @selected_tab = params[:selected_tab]
    
    cms_page_info('My Account')
    
    @pw = DefaultsHashObject.new(params[:pw])
    
    if request.post? 
    
      if params[:admin] && permit?('admin')
        @notice = 'Updated Admin Options'.t
        options = params[:admin]
        
        if Configuration.languages.include?(options[:language])
          Locale.set(options[:language])
          session[:cms_language] = options[:language]
                    
        end
        
        session[:context_translation] = options[:translation_options].include?('translate')
      elsif params[:pw]
        if !myself.validate_password(params[:pw][:current_password])
          @notice = "Current password is not valid".t
        elsif params[:pw][:new_password] == ''
          @notice = "Password cannot be empty".t
        elsif params[:pw][:new_password] != params[:pw][:confirm]
          @notice = "Passwords do not match".t
        else
          me = myself
          me.password = params[:pw][:confirm]
          me.save

          if me.editor?
            me.update_domain_emails
            me.update_editor_login
          end

          @notice = 'Updated Password'
          @pw = DefaultsHashObject.new()
        end
      end
    end
    
    @languages = Configuration.languages.collect { |lang| [ lang.upcase, lang ] }
    @admin  = DefaultsHashObject.new(:language => Locale.language_code,
                              :translation_options => session[:context_translation] ? ['translate'] : [])
  
  end
  
end
