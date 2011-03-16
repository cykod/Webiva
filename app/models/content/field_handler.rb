# Copyright (C) 2009 Pascal Rettig.



# Defines a content model FieldHandler which allows the addition of
# additional fields onto the custom content model system
class Content::FieldHandler 


  # Registers new field types with the system. See core_field.rb for an example
  def self.register_content_fields(field_info)
  
    module_name = self.to_s.underscore

    # Add in the module name    
    field_info.each do |fld|
      fld[:module] = module_name

      if ! fld.has_key?(:simple)
        fld[:simple] = fld.has_key?(:relation) ? false : true
      end
    end
    
    # Create the fields class method
    cls = class << self; self; end
    cls.send(:define_method,:fields) do
      field_info
    end
    
    # Generate the Hash
    field_hash_info = field_info.index_by { |fld| fld[:name] }
    
    # Generate the Hash class method
    cls.send(:define_method,:field_hash) do
      field_hash_info
    end
  
  end
  
  # Regiters new dynamic fields with the system (which allow publications
  # to automatically assign values to fields dynamically) see
  # core_field.rb for an example
  def self.register_dynamic_fields(dynamic_field_info_raw)
    module_name = self.to_s.underscore

    dynamic_field_info = []
    dynamic_field_info_raw.each do |identifier,label|
      dynamic_field_info << { :name => identifier.to_sym,
                          :label => label }
    end
    
    
    # Add in the module name    
    dynamic_field_info.each { |fld| fld[:module] = module_name }
    
    # Create the fields class method
    cls = class << self; self; end
    cls.send(:define_method,:dynamic_fields) do
      dynamic_field_info
    end
    
    # Generate the Hash
    dynamic_field_hash_info = dynamic_field_info.index_by { |fld| fld[:name] }
    
    # Generate the Hash class method
    cls.send(:define_method,:dynamic_field_hash) do
      dynamic_field_hash_info
    end
      
  
  end

end
