# Copyright (C) 2009 Pascal Rettig.



# Methods for generating the actual content model class 
# from a ContentModel object
module Content::ContentModelGenerator

  # Generates a subclass of ContentModelType that behaves like a 
  # standard DomainModel class for a CustomContentModel
  def content_model(force=false)
    clses = DataCache.local_cache("content_models_list") || {}
    cls = clses[self.table_name]
    return cls[0] if cls && !force
    
    class_name = self.table_name.classify
    cls = nil
    Object.class_eval do
      #remove_const class_name if const_defined? class_name
      cls = Class.new(ContentModelType) #
      #cls = const_set(class_name.to_s, Class.new(ContentModelType))
    end

    cls.set_class_name class_name
    
    cls.set_table_name self.table_name

    cls.cached_content

    # Setup the fields in the model as necessary (required, validation, etc)
    self.content_model_fields.each { |fld| fld.setup_model(cls) }

    if !self.identifier_name.blank?
      identifier_func = <<-SRC
        def identifier_name
          @identifier_name ||= variable_replace("#{self.identifier_name.gsub('"','\\"')}",self.attributes.symbolize_keys)
        end
      SRC

      cls.class_eval identifier_func, __FILE__, __LINE__
    elsif data_field = self.content_model_fields.detect { |fld| fld.data_field? }
      identifier_func = <<-SRC
        def identifier_name
          self.send(:#{data_field.field}).to_s
                  end
      SRC

      cls.set_identifier_field data_field.field

      cls.class_eval identifier_func, __FILE__, __LINE__
    else
      identifier_func = <<-SRC
        def identifier_name
          " #" + self.id.to_s 
        end
      SRC

      cls.class_eval identifier_func, __FILE__, __LINE__

    end
      
      if self.show_tags?
        cls.has_content_tags
      end
      
      self.model_generator_features.each do |feature|
        feature.model_generator(self,cls)
      end
      
      content_model_id = self.id
      cls.send(:define_method,:content_model_id) { content_model_id }
      if self.create_nodes?
        cls.content_node :container_type => 'ContentModel',:container_field => :content_model_id
        cls.has_one :content_node, :foreign_key => :node_id, :conditions => "node_type = " + DomainModel.connection.quote(class_name)
        cls.send(:define_method,:build_content_node) do 
          ContentNode.new(:node_type => class_name, :node_id => self.id)
        end
      end

      clses = DataCache.local_cache("content_models_list") || {}
      clses[self.table_name] = [ cls, class_name.to_s ]
      DataCache.put_local_cache("content_models_list", clses)
      cls
  end


    alias_method :model_class, :content_model

end
