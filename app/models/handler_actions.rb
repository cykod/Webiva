# Copyright (C) 2009 Pascal Rettig.

module HandlerActions

  def self.append_features(base) #:nodoc:
    super
    base.extend(ClassMethods)
  end
  
  def get_handlers(component,handler=nil,initialized=false)
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
  
  # Returns an array of instances for all supported handlers of a certain type
  # and passes initialize_args to the handler class new method
  def get_handler_instances(component,handler_name,*initialize_args)
    get_handler_info(component,handler_name).map { |h| h[:class].new(*initialize_args) }
  end
  
  def get_handler_instance(component,handler_name,identifier,*initialize_args)
    h = get_handler_info(component,handler_name,identifier)
    if h
      h[:class].new(*initialize_args)
    else
      nil
    end
  end
  
  module  ClassMethods

    def get_handlers(component,handler=nil,initialized = false)
      handlers = DataCache.get_cached_container("Handlers","Active") unless initialized || RAILS_ENV != 'production'
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

      if handler
        (handlers[component.to_sym]||{})[handler.to_sym] || []
      else
        (handlers[component.to_sym] || {}).values.inject([]) { |a,b| a.concat(b) }
      end
    end

    def get_handler_options(component,handler_name,initialized=false)
      handlers = get_handlers(component,handler_name,initialized)
      handlers.collect do |handler|
        cls = handler[0].constantize

        if block_given?
          if yield handler, cls
            [ cls.send("#{component}_#{handler_name}_handler_info")[:name].t, handler[0].underscore ]
          else
            nil
          end
        else
          [ cls.send("#{component}_#{handler_name}_handler_info")[:name].t, handler[0].underscore ]
        end
      end.compact
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
