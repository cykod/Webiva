# Copyright (C) 2009 Pascal Rettig.



class ContentModelFeature < DomainModel

  serialize :feature_options
  belongs_to :content_model
  
  before_save :update_callbacks
  
  def validate
    opts = options(true)
    self.errors.add_to_base('options are not valid') unless opts.valid?
  end
  
  def before_save
    self.feature_options = options.to_hash # Get ourselves a nice clean hash
  end
  
  def feature
    return @feature_cls if @feature_cls
    @feature_cls =   self.feature_handler.camelcase.constantize
  end
  
  def name
    self.feature.content_feature_handler_info[:name]
  end
  
  def description
    if self.feature.respond_to?(:description)
      self.feature.description(self.feature_options)
    else
      name
    end
  end
  
  def options(force=false)
    return @options_object if @options_object && !force
    @options_object = self.feature.options(self.feature_options)
  end
  
  def options_partial
    self.feature.options_partial
  end

  
  def feature_instance
    self.feature.new(self)
  end
    
  def update_callbacks
    cbs = (self.feature.content_feature_handler_info[:callbacks] || []).clone
    
    # Update the callbacks indexers
    %w( model_generator more_table_actions table_columns header_actions add_migration remove_migration ).each do |cb|
      self.send("#{cb}_callback=",cbs.include?(cb.to_sym) ? true : false)
    end
  end


  def model_generator(content_model,cls)
    feature_instance.model_generator(content_model,cls)
  end

end
