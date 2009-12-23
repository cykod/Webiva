# Copyright (C) 2009 Pascal Rettig.

module HandlerActions

  def self.append_features(base) #:nodoc:
    super
    base.extend(ClassMethods)
  end
  
  def get_handlers(component,handler,initialized=false)
    self.class.get_handlers(component,handler,initialized)
  end
  
  def get_handler_options(component,handler_name,initialized=false)
    self.class.get_handler_options(component,handler_name,initialized)
  end

  def get_handler_values(component,handler_name,initialized=false)
    self.class.get_handler_options(component,handler_name,initialized).map { |elm| elm[1]}
  end
  
  def get_handler_info(component,handler_name,identifier=nil,initialized=false)
    self.class.get_handler_info(component,handler_name,identifier,initialized)
  end
  
  
  module  ClassMethods

    def get_handlers(component,handler,initialized = false)
      component = component.to_sym; handler = handler.to_sym
      handlers = DataCache.get_cached_container("Handlers","Active") unless initialized || RAILS_ENV == 'development'
      unless handlers
        mods = initialized ? SiteModule.initialized_modules_info :  SiteModule.enabled_modules_info
        handlers = {}
        mods.each do |mod|
          mod.admin_controller_class.get_module_handlers.each do |handler_mod,mod_handlers|
            handlers[handler_mod.to_sym] ||= {}
            mod_handlers.each do |mod_handler,handler_info|
               handlers[handler_mod.to_sym][mod_handler.to_sym] ||= []
               handlers[handler_mod.to_sym][mod_handler.to_sym] += handler_info
            end
          end
        end
        
        # Manually add in the ContentController and EditController handlers
        [ ContentController, EditController].each do |cls|
          cls.get_module_handlers.each  do |handler_mod,mod_handlers|
            handlers[handler_mod.to_sym] ||= {}
            mod_handlers.each do |mod_handler,handler_info|
               handlers[handler_mod.to_sym][mod_handler.to_sym] ||= []
               handlers[handler_mod.to_sym][mod_handler.to_sym] += handler_info
            end
          end
        end
        DataCache.put_container("Handlers","Active",handlers)  unless initialized || RAILS_ENV == 'development'
      end
      return (handlers[component]||{})[handler] || []

    end
    
    def get_handler_options(component,handler_name,initialized=false)
      handlers = get_handlers(component,handler_name,initialized)
      handlers.collect do |handler|
        cls = handler[0].constantize
        [ cls.send("#{component}_#{handler_name}_handler_info")[:name].t, handler[0].underscore ]
      end
    end
    
    def get_handler_info(component,handler_name,identifier=nil,initialized=false)
      handlers = get_handlers(component,handler_name,initialized)
      handler_info = handlers.collect do |handler|
        cls = handler[0].constantize
         info = cls.send("#{component}_#{handler_name}_handler_info").clone
         info[:class_name] = handler[0]
         info[:class] = cls
         info[:identifier] = handler[0].underscore
         return info if identifier && info[:identifier] == identifier
         info
      end
      identifier ? nil : handler_info
    end
  end
end
