
module ModelExtension::HandlerExtension
  module ClassMethods
    def handler(name, component, handler_name, opts={})
      opts[:field] ||= "#{handler_name}_handler".to_sym
      opts[:data] ||= :data
      
      field = opts[:field]
      data = opts[:data]
      
      class << self; self end.send(:define_method, "#{name}_handlers") do
        self.get_handler_info(component, handler_name)
      end
      
      class << self; self end.send(:define_method, "#{name}_select_options") do |*args|
        opts = args[0] || {}
        handlers = self.send("#{name}_handlers")
        select_options = handlers.collect { |h| [h[:name], h[:identifier]] }
        select_options.sort! { |a, b| a[:name] <=> b[:name] } if opts[:sort]
        select_options
      end

      class << self; self end.send(:define_method, "#{name}_select_options_with_nil") do |*args|
        [["--Select #{component.to_s.titleize} #{handler_name.to_s.titleize}--", nil]] + self.send("#{name}_select_options", args[0])
      end

      define_method "#{name}_info" do
        self.get_handler_info(component, handler_name, self.send(field)) unless self.send(field).blank?
      end
      
      define_method "#{name}_class" do
        self.send("#{name}_info")[:class] if self.send("#{name}_info")
      end

      define_method "create_#{name}" do
        self.send("#{name}_class").new(self[data]) if self.send("#{name}_class")
      end

      define_method "#{name}_name" do
        self.send("#{name}_info")[:name] if self.send("#{name}_info")
      end

      define_method name do
        return instance_variable_get("@#{name}") if instance_variable_get("@#{name}")
        instance_variable_set("@#{name}", self.send("create_#{name}"))
      end
      
      define_method "validate_#{name}" do
        unless self.send(field).blank?
          handler = self.send name
          if handler
            self.errors.add(data, 'is invalid') unless handler.valid?
          else
            self.errors.add(field, 'is invalid')
          end
        end
      end
      
      define_method "update_#{name}" do
        handler = self.send name
        self[data] = handler ? handler.to_hash : {}
      end

      serialize data
      validate "validate_#{name}".to_sym unless opts[:no_validation]
      before_save "update_#{name}" unless opts[:no_update]
    end
  end
  
  def self.append_features(mod) #:nodoc:
    super
    mod.extend ModelExtension::HandlerExtension::ClassMethods
  end
end
