# Copyright (C) 2009 Pascal Rettig.


class Content::CorePublication::EditPublication < Content::CorePublication::CreatePublication #:nodoc:all
  # All the same options as the edit publication 
  
  register_triggers :view, :edit, :create
  
  def preview_data
    cls = @publication.content_model.content_model
    cls.find(:first) || cls.new
  end
  
end

