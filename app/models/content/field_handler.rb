# Copyright (C) 2009 Pascal Rettig.



class Content::FieldHandler 


  def self.register_content_fields(field_info)
  
    module_name = self.to_s.underscore

    # Add in the module name    
    field_info.each { |fld| fld[:module] = module_name }
    
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

# # Returns a hash of options for a specific field type
# def self.set_field_options(field_type,options)
#  {}
# end  

# # Modifies the parameters field based on the attributes of the field
# def self.modify_entry_parameteres(fld,parameters)
#   nil # Don't do anything by default
# end
# 
# 
# 
# def self.filter_variables(field_type,publication_field)
#   [ ('filter_' + publication_field.id.to_s).to_sym ]
# end
 

end
