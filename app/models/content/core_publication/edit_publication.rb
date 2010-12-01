# Copyright (C) 2009 Pascal Rettig.


class Content::CorePublication::EditPublication < Content::CorePublication::CreatePublication #:nodoc:all
  # All the same options as the edit publication 
  #
  field_types :input_field, :preset_value, :dynamic_value, :entry_value
  
  register_triggers :view, :edit, :create
  field_options :filter
  def preview_data
    cls = @publication.content_model.content_model
    cls.find(:first) || cls.new
  end

  
  def filter?; true; end
  
end

