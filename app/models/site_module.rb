# Copyright (C) 2009 Pascal Rettig.

class SiteModule < DomainModel
#  has_many :site_nodes, :dependent => :destroy
  has_many :page_paragraphs, :dependent => :destroy
  
  serialize :options

  has_options :status, [['Initializing','initializing'],
                       ['Inititalized','initialized'],
                       ['Active','active'],
                       ['Available','available']]
  
  def get_renderers
    renderers = []
    Dir.glob("#{RAILS_ROOT}/vendor/modules/#{name}/app/controllers/#{name}/[a-z0-9\-_]*_renderer.rb") do |file|
      if file =~ /#{name}\/([a-z0-9\-_]+)_renderer.rb$/
        renderer_name = $1
        cls_name = "#{name.camelcase}::#{renderer_name.camelcase}Renderer"
        renderers <<  cls_name.constantize
      end
    end
    
    renderers
  end
  
  
  def get_features
    features = []
    Dir.glob("#{RAILS_ROOT}/vendor/modules/#{name}/app/controllers/#{name}/[a-z0-9\-_]*_feature.rb") do |file|
      if file =~ /#{name}\/([a-z0-9\-_]+)_feature.rb$/
        feature_name = $1
        cls_name = "#{name.camelcase}::#{feature_name.camelcase}Feature"
        features <<  cls_name.constantize
      end
    end
    
    features
  end
    
  
  def get_dispatcher(site_node)

    dispatcherClass = "#{self.module_name.camelcase}::#{self.module_name.camelcase}Dispatcher".constantize
    
    dispatcherClass.new(self,site_node)
  end

  def self.module_info(name)
    {}
  end
  
  def self.activated_modules
    SiteModule.find(:all,:conditions => 'status = "active"')
  end
  
  def self.module_enabled?(md)
    enabled_modules.include?(md.to_s.underscore.downcase)
  end

  

  
  def self.enabled_modules
    mds = DataCache.get_cached_container("Modules","Active")
    
    unless mds
      mds = self.activated_modules().collect do |active_mod|
        active_mod.name
      end
      DataCache.put_container("Modules","Active",mds)
    end 
    mds
  end
  
  # Get a list of all the modules that are available or active
  def self.available_modules(domain)
    mods = DomainModule.all_modules(domain).find_all do |mod|
      mod[:status] == 'available'
    end
    
    mods.each do |mod|
      entry = SiteModule.find_by_name(mod[:module])
      if entry
        mod[:status] = entry[:status]
      end
    end
  end

  def after_save
    DataCache.put_local_cache(:site_modules_active,nil)
  end
  
  def self.enabled_modules_info
    DataCache.local_cache(:site_modules_active) || DataCache.put_local_cache(:site_modules_active, self.find(:all,:conditions => 'status = "active"'))
  end

  def self.initialized_modules_info
    self.find(:all,:conditions => 'status IN ("active","initialized")')
  end
  
  # get a list of only those active modules
  def self.active_modules(domain)
    self.available_modules(domain).find_all do |mod| 
      mod[:status] == 'active'
    end
  end
  
  def self.site_node_module_active?(module_name)
    reg = /^\/([^\/]+)\/([^\/]+)$/
    if module_name =~ reg
      comp = $1
      mod = $2
      
      if comp == 'editor'
        ctrl_class = Editor::AdminController
      else
	comp  =  self.find_by_name(comp,:conditions => "status='active'")
	ctrl_class = comp.admin_controller_class if comp
      end
      	
      if ctrl_class
        ctrl_class.get_modules_for.each do |md|
          if md[:module].to_s == mod.to_s
            return true
          end
        end
      end
    end
    
    false
  end
  
  def self.structure_modules
    structure_modules = []
    self.find(:all,:conditions => "status='active'").each do |comp|
      comp.admin_controller_class.get_modules_for.each do |mod|
        mod[:component] = comp[:name]
        mod[:path] = "/#{comp[:name]}/#{mod[:module]}"
        structure_modules << mod
      end
    end
    Editor::AdminController.get_modules_for.each do |mod|
      mod[:component] = 'editor'
      mod[:path] = "/editor/#{mod[:module]}"
      structure_modules << mod
    end

    structure_modules
  end
  
  def self.get_module_paragraphs
    paragraphs = {}
    last_header = ''
    self.find(:all,:conditions => "status='active'").each do |comp|
      Dir.glob("#{RAILS_ROOT}/vendor/modules/#{comp.name}/app/controllers/#{comp.name}/[a-z0-9\-_]*_controller.rb") do |file|
        
        if file =~ /\/([a-z0-9\-_]+)_controller.rb$/
          controller_name = $1
          cls = "#{comp.name.camelcase}::#{controller_name.camelcase}Controller".constantize
          
  
          if(cls.ancestors.detect { |elem| elem.to_s == "ParagraphController" } )
            
            header = cls.get_editor_header
            paras = cls.get_editor_for
            
            if header
              paragraphs[header[0]] = [header[0],header[1],[]] if header[0] != last_header
              last_header = header[0]
            elsif paras && paras.length > 0
              raise "Missing editor_header in #{cls.to_s}"
            end
            if paras
                
              paras.each do |para|
                paragraphs[header[0]][2] << [ comp.name, para[0].to_s, para[1][:name] || para[0].to_s.humanize, "/#{comp.name}/#{controller_name}", para[1][:features] || [] ]
              end
            end
          end
        end
      end
    end
    
    paragraphs
  end

  def self.complete_module_initialization(name)
    mdl = SiteModule.find_by_name_and_status(name.to_s.underscore,'initialized')
    if mdl
      mdl.update_attribute(:status,'active')
      mdl.expire_site
    end
  end

  def self.generate_deactivation_list(mod_list)
    domain = Domain.find_by_id(DomainModel.active_domain_id)
    all_modules =  DomainModule.all_modules(domain)

    mods = enabled_modules.map do |mod|
      all_modules.detect {  |md| md[:module] == mod }
    end.compact

    deactivated_list = mod_list.select do |mod|
      all_modules.detect {  |md| md[:module] == mod }
    end.compact
   

    # Go through each of the enabled modules and make
    # sure that any modules that have dependences are ok
    mods.each do |mod_info|
      # return if we have dependencies that aren't going to be deactivated as well
      if mod_info[:dependencies]
        mod_info[:dependencies].each do |dep|
          if deactivated_list.include?(dep) && !deactivated_list.include?(mod_info[:module])
            return false
          end
        end
      end
      mod_info[:module]
    end

    deactivated_list
  end
  
  def self.generate_activation_list(mod_list)
    domain = Domain.find_by_id(DomainModel.active_domain_id)
    all_modules =  DomainModule.all_modules(domain)

    mods = mod_list.map do |mod|
      all_modules.detect {  |md| md[:module] == mod }
    end.compact

    if mods.length != mod_list.length
      return false
    end

    # return an activation list if everything is kosher,
    # otherwise return false
    prepend_list = []
    activation_list = mods.map do |mod_info|
      if !mod_info[:status] == 'available'
        return false
      end
      
      # return if we have dependencies that aren't activated or going to be activated
      # otherwise add the dependencies to the beginning of the prepend list
      if mod_info[:dependencies]
        mod_info[:dependencies].each do |dep|
          if  mod_list.include?(dep)
            prepend_list << dep
          elsif !SiteModule.module_enabled?(dep)
            return false
          end
        end
      end
      mod_info[:module]
    end
    
    (prepend_list.reverse + activation_list).uniq
  end

  def self.activate_module(domain,name,opts={})
    mod = SiteModule.find_by_name(name) || SiteModule.new(:name => name)
    available = DomainModule.module_info(domain,name) 
    if available && (available[:status] == 'available' || opts[:force])
      available[:dependencies].each do |depend|
        if opts[:force]
          SiteModule.activate_module domain, depend, opts
        else
          return nil unless SiteModule.module_enabled?(depend)
        end
      end
      mod.status = 'initializing'
      return mod if mod.save
    end

    return nil
  end


  # Activate a list of modules, checks dependencies for each module
  # 
  def self.activate_modules(mod_list)
    domain = Domain.find_by_id(DomainModel.active_domain_id)
    all_modules =  DomainModule.all_modules(domain)

    mod_list.map do |name|
      available = DomainModule.all_modules(domain).detect { |md| md[:module] == name }
      if available && available[:status] == 'available'
        available[:dependencies].each do |depend|
          return nil if !SiteModule.module_enabled?(depend) && !mod_list.include?(depend)
        end
        mod = SiteModule.find_by_name(name) || SiteModule.new(:name => name)
        mod.status = 'initializing'
        mod.save
        mod.id
      end
    end.compact
  end

  
  def self.deactivate_modules(names)
    domain = Domain.find_by_id(DomainModel.active_domain_id)
    all_modules =  DomainModule.all_modules(domain)
    names.each do |name|
      mod = SiteModule.find_by_name(name)
      if(mod && (mod.status == 'active' || mod.status == 'initialized'))
        available =all_modules.detect { |md| md[:module] == name }
        if available && available[:status] == 'available'
          mod.update_attribute(:status,'available')
        else
          mod.destroy
        end
      end
    end
    expire_site
  end

  def display_name
    self.name.to_s.humanize
  end
  
  def admin_controller
    "/#{self.name}/admin"
  end
  
  def admin_controller_class
    "#{self.name.camelcase}::AdminController".constantize
  end
  
  def self.get_module(name)  
    self.find_by_name(name)
  end

  def options_url
    if(admin_controller_class.method_defined?('options'))
      {  :controller => self.admin_controller, 
         :action => 'options'}
    else
      nil
    end
  end

  def post_initialization!
    if  self.status == 'initialized' 
      self.admin_controller_class.content_node_type_generate
      if ( self.admin_controller_class.method_defined?('options') ||
           self.admin_controller_class.respond_to?('module_options') )
        if self.admin_controller_class.respond_to?('module_options')
          opts = self.admin_controller_class.module_options
          if opts.valid?
            self.update_attribute(:status,'active')
          end
        end 
      else
        self.update_attribute(:status,'active')
      end
    end
  end
  
  protected
  
  def options_class(hsh)
    adminClass = "#{self.module_name.camelcase}::AdminController".constantize
    
    optionsClass = "#{self.module_name.camelcase}::AdminController::Options".constantize
    
    optionsClass.new(hsh)
  end
  
  def validate_on_update
    errors.add_to_base("Please enter a name") if name.empty?
  end
  
  
 def info
    return @info if @info
    moduleClass = "#{self.name.camelize}::AdminController".constantize
    @info = moduleClass.info
    
    return @info
  end
  
  def menu
    return @menu if @menu
    moduleClass = "#{self.name.camelize}::AdminController".constantize
    @menu = moduleClass.menu
    
    return @menu
  end
  
  def paragraphs
    return @paragraphs if @paragraphs
    moduleClass = "#{self.name.camelize}::AdminController".constantize
    @paragraphs = moduleClass.paragraphs
    
    return @paragraphs
  end

  def moduleNode(node_id)
    moduleClass = "#{self.name.camelize}::Module".constantize
    
    moduleClass.new
  
  end
  
  
   def self.get_module_info(cms_module,domain) 
        moduleName = cms_module
        moduleClass = "#{moduleName.camelcase}::AdminController".constantize
        moduleEntry = domain.domain_modules.find_by_name(moduleName)
        moduleInfo = moduleClass.info
        
        moduleStatus = :unavailable
        if !moduleEntry.nil?
          moduleOptions = (!moduleEntry.options.nil? && moduleEntry.options.length > 0) ? Marshal.load(moduleEntry.options) : {}
          moduleStatus = moduleEntry.status.to_sym
        elsif moduleInfo.module_type == :included
          moduleStatus = :available
          moduleOptions = {}
        elsif moduleInfo.module_type == :hidden
          moduleStatus = :hidden
          moduleOptions = {}
        end
        
        { :name => moduleName,
          :status => moduleStatus,
          :options => moduleOptions,
          :info => moduleClass.info,
          :entry => moduleEntry || nil }
  end

  def self.get_domain_modules(domain)
    modules = []
    Dir.glob("#{RAILS_ROOT}/vendor/modules/[a-z]*") do |file|
      if file =~ /\/([a-z_-]+)\/{0,1}$/
        mod = DomainModule::get_module_info($1,domain)
        modules <<  mod if mod[:status] != :hidden
        
      end
    end
    
    modules
  end

  def self.migrate_domain_components(params = { })
    # do some sanitization on the activation list just in case
    list = params[:activation_list].map { |mod| mod.gsub(/[^0-9a-zA-Z_\-]+/,'')}
    ok = `cd #{RAILS_ROOT};rake cms:migrate_domain_components DOMAIN_ID=#{DomainModel.active_domain_id} COMPONENT=#{list.join(',')}`
    expire_site
  end

  def migrate_domain_component(params = {})
    
    ok = `cd #{RAILS_ROOT};rake cms:migrate_domain_components DOMAIN_ID=#{DomainModel.active_domain_id} COMPONENT=#{self.name}`
    expire_site
  end
end
