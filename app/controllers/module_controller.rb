# Copyright (C) 2009 Pascal Rettig.

class ModuleController < CmsController  # :nodoc: all
  layout "manage"

  include ActiveTable::Controller
  
 # skip_before_filter :validate_paragraph, :only => :admin
    before_filter :validate_module
    layout 'manage'
    
  
  protected

    def validate_module
      if !active_module(self.class.to_s.include?('AdminController')) && RAILS_ENV != 'test'
        redirect_to :controller => '/modules'
        return false
      else
        return true
      end
      
    end
    
  def self.user_actions(names)
    self.skip_before_filter :validate_module, :only => names
  end
    
  def active_module(adm=false)
    info = self.class.get_component_info

    return adm ? get_module_info(adm) : SiteModule.module_enabled?(info[0])
  end

  def get_module_info(adm=false)
    return @mod if @mod
    info = self.class.get_component_info

    # Allow access to the AdminController if we're in the initialized state
    if adm
      @mod = SiteModule.find_by_name(info[0].to_s.underscore.downcase,:conditions => {:status => [ 'active','initialized' ] })
    else
      
      @mod = SiteModule.find_by_name_and_status(info[0].to_s.underscore.downcase,'active')
    end
    if @mod
      @mod.options = {} unless @mod.options.is_a?(Hash)
    end
    @mod
  end
  
  # Default get component info - just pull the module name
  def self.get_component_info
    name = self.class.to_s.split("::")[0].underscore
    options[:access] ||= :private
    options[:description] ||= ''
      
    sing = class << self; self; end
    sing.send :define_method, :get_component_info do 
      return [name,options]
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

  def self.get_module_handlers
    {}
  end

  def self.register_handler(component,handler,class_name,options={})
    component = component.to_sym; handler = handler.to_sym
    options[:handler] = handler
    handlers = self.get_module_handlers
    handlers[component] ||= {}
    handlers[component][handler] ||= []
    handlers[component][handler] << [ class_name, options ]
    sing = class << self; self; end
    sing.send :define_method, :get_module_handlers do 
      handlers
    end 
  end
  
  def self.linked_models(model,elements)
 # Use post_destroy and post_save to prevent salesforce transaction issue
    elements = elements.map do |elm|
        if elm.is_a?(Array)
          elm.map(&:to_s)
        else
          [ elm.to_s,"#{model.to_s.underscore}_id" ]
        end
    end
 
    register_handler :model, model, "ModuleController::LinkedModelExtension", :actions => [ :post_destroy  ], :models => elements  
  end
  
  class LinkedModelExtension < DomainModelExtension
   def post_destroy(mdl)
    default_field = mdl.class.to_s.underscore + "_id"
    options[:models].each do |model|
      if model.length == 3
        model[0].classify.constantize.destroy_all(["`#{model[1]}` = ? AND `#{model[2]}` =  ?", mdl.class.to_s , mdl.id ])
      else
        model[0].classify.constantize.destroy_all(["`#{model[1]}` =  ?", mdl.id ])
      end
    end
   end
  end
  
  def self.get_module_crons; []; end

  def self.register_cron(method,class_name,options={})
    crons = self.get_module_crons
    crons << [ method, class_name, options ]
    sing = class << self; self; end
    sing.send :define_method, :get_module_crons do 
      crons
    end 
  end
  
  def self.register_action(action_name,options={})
    register_handler(:action,action_name,nil,options)
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
  
  # Content Node Type 
  def self.content_node_type(content_name,content_type,options = {})
    options = options.clone
    
    options[:component] = get_component_info[0].to_s
    options[:content_name] = content_name
    options[:content_type] = content_type
    options.symbolize_keys!
    
    opts = self.content_node_type_options
    opts << options
    (class << self; self; end).class_eval do
      define_method(:content_node_type_options) do 
        opts
      end
    end
  end
  
  def self.content_node_type_options
    []
  end
  
  def self.content_node_type_generate
     options_list = self.content_node_type_options
     
     options_list.each do |opts|
       title_field = (opts[:title_field] || 'name').to_s
       url_field = (opts[:url_field] || 'id').to_s
       
       if(!ContentType.find_by_content_type(opts[:content_type])) 
         ContentType.create(:component => opts[:component],
                            :content_name => opts[:content_name],
                            :content_type => opts[:content_type],
                            :title_field => title_field,
                            :url_field => url_field,
                            :editable => opts.has_key?(:editable) ? opts[:editable] : true,
                            :search_results => opts[:search] )
       end
     end
  end
    
  
end
