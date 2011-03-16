# Copyright (C) 2009 Pascal Rettig.

class OptionsController < CmsController  # :nodoc: all
  layout "manage"

  
  permit ['editor_design_templates','editor_permissions','editor_site_management','editor_emails'], :only => :index
  
  permit 'editor_site_management', :except => :index
  
  

  def index
    cms_page_info 'Options', 'options'	
    
    @subpages =
      [
       [ "Editor\nAccounts", :editor_editors, "website_editors.png",
         { :controller => 'editors' }, 
         "Administor editor accounts, managing who can edit pages on the system" ]
      ]

    if Configuration.domain_info.email_enabled?
      @subpages <<
        [ "Domain\nEmails", :editor_emails, "emarketing_templates.gif",
          { :controller => '/email' },
          "Manage the email accounts associated with this domain" ]
    end

    @subpages += 
      [ 
       [ "Permissions", :editor_permissions, "website_permissions.png",
         { :controller => '/permissions' },
         "Administor permissions, controlling which user profiles has access to features of the site."
       ],
       [ "Website\nConfiguration", :editor_site_management, "website_configuration.png",
         { :controller => '/options', :action => 'configuration' }, "Presents various site-wide configuration options that can be set up. Configure System Languages."
       ],
       [ "Themes", :editor_design_templates, "website_themes.png",
         { :controller => '/templates' },
         "Create, Select and Edit site themes. Themes control the look of your site."
       ],
       [ "Modules", :editor_site_management, 'website_modules.png',
         {  :controller => '/modules'},
         "Enables additional CMS functionalities via plugin modules. Module features can be accessed either via website, page editor paragraph types, or additional administrative pages."
       ],
       [ "Site\nDomains", :editor_site_management, 'website_domains.png',
         { :controller => '/domains' },
         "Administer the domains where this site can be accessed."
       ]
      ]
  end
  
  register_permission_category :editor, 'Webiva', 'Permissions relating to the core webiva system'
  register_permissions :editor, [ [:website, 'Website', 'View page layout' ],
                                  [:structure, 'Structure', 'Edit Site Structure' ],
                                  [:structure_advanced, 'Advanced Structure', 'Edit Site structure and modifiers' ],
                                  [:editor, 'Editor', 'Edit pages'],
                                  [:files, 'Files & Images', 'Upload files and images' ],
                                  [:content, 'Content', 'View content models' ],
                                  [:content_configure, 'Content Configure','Configure content models and publications' ],
                                  [:visitors, 'Site Visitors', 'View site visitors'],
                                  [:members, 'Member Management', 'Edit registered Users'],
                                  [:editors, 'Editor Management', 'Admin site editors'],
                                  [:emails, 'Edit Email Accounts', 'Admin email accounts'],
                                  [:mailing, 'Mailing Management', 'Edit mail templates'],
                                  [:design_templates, 'Design Templates','Access Design templates'],
                                  [:access_tokens,'Access Tokens','Access Token Management'],
                                  [:permissions, 'Permissions', 'Configure user profiles and permissions'],
                                  [:site_management, 'Site Management', 'Manage site options']
                                ]
  
  cms_admin_paths "options",
  "Options" =>  {:controller => 'options'},
  "Configuration" =>  { :action => 'configuration' },
  "Image Sizes" => {:action => 'image_sizes' }
  
  def configuration
    cms_page_path [ "Options" ], "Configuration"


     @subpages = [
       [ "Domain Options", :editor_editors, "config_domain.png",
         { :action => 'domain_options' }, 
        "Manage domain level options"
       ],
       [ "Languages", :editor_editors, "config_languages.png",
         { :action => 'languages' }, 
        "Configure the available languages on the site"
       ],
       [ "Files", :editor_editors, "config_files.png",
         { :action => 'files' }, 
        "Manage the file processor for Files uploaded to the system"
       ],
       [ "Image Sizes", :editor_editors, "config_image_sizes.png",
         { :action => 'image_sizes' }, 
        "Configure image sizes available on the site"
       ]
     ]
  end
  
  def languages
    cms_page_path [ "Options", "Configuration" ], "Language"
    
    @languages = GlobalizeLanguage.find_common().collect do |lang|
      [ lang.iso_639_1, lang.english_name.t ]
    end
    
    @languages.sort! { |x,y| x[1] <=> y[1] }
    
    @language_list = Configuration.languages()
    
    
    @selected_languages = @language_list.collect do |lang|
      [ lang, GlobalizeLanguage.find_by_iso_639_1(lang).english_name.t ]
    end
    
  end
  
  def domain_options
    cms_page_path [ "Options", "Configuration" ], "Domain Options"
    
    @options =  Configuration.options(params[:options])
    
    if request.post? && params[:options] && @options.valid?
      @config = Configuration.retrieve(:options)
      
      if @config.options['gallery_folder'] != @options.gallery_folder
        # TODO - Fix & Modularize
        old_gal = DomainFile.find_by_id(@config.options['gallery_folder'])
        old_gal.update_attribute(:special,'') if old_gal
        new_gal = DomainFile.find_by_id(params[:options][:gallery_folder])
        new_gal.update_attribute(:special,'galleries') if new_gal
      end
      @config.options = @options.to_hash
      
      @config.save
      Configuration.retrieve(:options)
      flash[:notice] = 'Updated Domain Options'.t
      redirect_to :action => 'configuration'
    end
    
    handlers = get_handler_info(:members,:view)
    @member_tabs = handlers.map {|elm| [ elm[:name], elm[:identifier].to_s ] }

    @search_handler_options =  [['--Use Internal Search Engine--',nil]] + get_handler_options(:webiva,:search)
    @search_stats_handler_options = [['--Select a Search Tracker--',nil]] + get_handler_options(:webiva,:search_stats)
    @captcha_handler_options =  [['--Disable Captcha Support--',nil]] + get_handler_options(:webiva,:captcha)
    
  end
  
  def add_language 
    language = params[:language]
    lang =  [ language, GlobalizeLanguage.find_by_iso_639_1(language).english_name.t ]
    render :partial => 'language', :locals => { :lang => lang }
  end
  
  
  
  def save_language_configuration
    languages = params[:selected_languages] || []
    
    @valid_languages = []
    languages.each do |lang|
      if GlobalizeLanguage.find_by_iso_639_1(lang)
        @valid_languages << lang
      end
    end
    
    if @valid_languages.length == languages.length && @valid_languages.length > 0
      @config = Configuration.retrieve(:languages)
      
      @config.options[:list] = @valid_languages
      @config.save
      
      render :inline => 'Saved Changes'
    else
      render :inline => 'You must select a default language,<br/>Changes not saved'
    end
  end
  
  include ActiveTable::Controller
  
  active_table :image_sizes_table, DomainFileSize, 
  [ ActiveTable::IconHeader.new(nil,:width=>10),
    ActiveTable::StringHeader.new('name'),
    ActiveTable::StringHeader.new('size_name'),
    ActiveTable::StaticHeader.new('Final Size') ]
  
  def display_image_sizes_table(display=true)
    
    active_table_action('domain_file_size') do |action,fids|
      DomainFileSize.destroy(fids) if action == 'delete'
      DataCache.expire_container("Config")
    end

    @active_table_output = image_sizes_table_generate params, :order => 'name'
    
    render :partial => 'image_sizes_table' if display
  end
  
  def image_sizes
    cms_page_path [ "Options", "Configuration" ], "Image Sizes"
    
    @images  = DefaultsHashObject.new(params[:image_sizes])
    
    display_image_sizes_table(false)
  end
  
  
  def image_size
    @domain_file_size = DomainFileSize.find_by_id(params[:path][0]) || DomainFileSize.new()
    
    cms_page_path ["Options","Configuration","Image Sizes"], @domain_file_size.id ? [ "Edit %s",nil,@domain_file_size.name ] : "Create Image Size"
    
    if request.post? && params[:domain_file_size]
      operation_order = params[:operation_order].to_s.split("&").find_all() { |elm| !elm.strip.blank? }
      @domain_file_size.operations = operation_order.collect do |elm|
        params[:operation][elm].to_hash.symbolize_keys
      end
      
      if @domain_file_size.update_attributes(params[:domain_file_size])
        DataCache.expire_container("Config")
        redirect_to :action => 'image_sizes'
      end
    end
    
    
  end
  
  def add_operation
    @operation = DomainFileSize.new_operation(params[:operation])
    
    render :partial => 'operation', :locals => { :operation => @operation, :idx => params[:index] }
    
  end
  
  def files
    
    cms_page_path ["Options","Configuration"] ,"Files"
    
    @options = Configuration.file_types(params[:options])
    
    if request.post? && params[:options] && @options.valid?
      
      @config = Configuration.retrieve(:file_types)
      @config.options = @options.to_h
      
      @config.save
      DataCache.expire_container("Config")
      @updated = true
    end

    @handlers = get_handler_info(:website,:file)
    
    @available_processors = [['Local Storage','local']] + @handlers.collect { |hndl| [hndl[:name],hndl[:identifier]] }
    
  end
  
  def move_all
    
    @options = Configuration.file_types()
    DomainModel.run_worker('DomainFile',nil,:update_processor_all,{ :processor => @options.default })
    flash['notice'] = 'Updating all files to ' + @options.default
    redirect_to :action => 'files'

  end
  
end
