

module Dashboard::WidgetMethods #:nodoc:all

  def widget_options_validation
    options_object = self.options(self.data,true)
    if options_object
      if(!options_object.valid?)
        errors.add(:data)
      end
      self.data =options_object.to_hash
    end
  end

  def widget_class
    self.widget_class_name.constantize
  end

  def widget_class_name
    self.module.camelcase
  end
  
  def widget_options_class_name
    "#{self.widget_class_name}::#{self.widget.camelcase}Options"
  end

  def widget_options_class
    self.widget_options_class_name.constantize
  end


  def widget_description
    self.widget_class.widget_information(self.widget)[:name]
  end
  

  def options(val=nil,force=false)
    return nil unless self.module
    return @options if !val && @options && !force

    if self.site_widget
      @options = widget_options_class.new(site_widget.data)
    else
      @options = widget_options_class.new(val || self.data)
    end
  end

  def self.append_features(mod) #:nodoc:
    super
    mod.extend Dashboard::WidgetMethods::ClassMethods
  end


  module ClassMethods
    
    def widget_class_name(name)
      name.camelcase
    end
    
    def widget_options_class_name(name,widget)
      "#{widget_class_name(name)}::#{widget.camelcase}Options"
    end

    def widget_options_class(name,widget)
      self.widget_options_class_name(name,widget).constantize
    end
    


  end

end
