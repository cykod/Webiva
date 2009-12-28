
class Handlers::ParagraphFeature < HashModel

  attributes :feature_handler => nil,:feature_options => { }, :feature_type => nil


  def feature
    return @feature_cls if @feature_cls
    @feature_cls =   self.feature_handler.camelcase.constantize
  end
  
  def name
    self.feature.send("#{self.feature_type}_handler_info")[:name]
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
    @options_object = self.feature.paragraph_options(self.feature_options)
  end
  
  def options_partial
    self.feature.send("#{self.feature_type}_handler_info")[:paragraph_options_partial]
  end

  
  def feature_instance
   @feature_instance ||=  self.feature.new(self.feature_options)
  end

  def to_hash
    self.feature_options = self.options(true).to_hash
    super
  end

end
