
class ContentHashModelFeature < HashModel
  attributes :feature_handler => nil, :feature_options => nil,
    :model_generator_callback => nil,  :more_table_actions_callback => nil,
    :table_columns_callback => nil, :header_actions_callback => nil,
    :add_migration_callback => nil, :remove_migration_callback => nil

  def strict?; true; end

  def validate
    opts = options(true)
    self.errors.add_to_base('options are not valid') unless opts.valid?
  end
  
  def feature
    return @feature_cls if @feature_cls
    @feature_cls = self.feature_handler.camelcase.constantize
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

  def webform(form, result)
    feature_instance.webform(form, result) if feature_instance.respond_to?('webform')
  end

  def feature_options=(options)
    return unless options
    @feature_options = options.to_hash.symbolize_keys
    @feature_options[:matched_fields] = @feature_options[:matched_fields].to_hash.symbolize_keys if @feature_options[:matched_fields]
  end
end
