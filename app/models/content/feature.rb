# Copyright (C) 2009 Pascal Rettig.



class Content::Feature

  
  def initialize(content_model_feature)
    @feature = content_model_feature
    @options = content_model_feature.options
  end
  
  attr_reader :feature,:options
  
  def self.options_partial
    self.content_feature_handler_info[:options_partial]
  end

end
