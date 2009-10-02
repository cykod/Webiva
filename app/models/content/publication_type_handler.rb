# Copyright (C) 2009 Pascal Rettig.



class Content::PublicationTypeHandler 


  def self.register_publication_types(types)
  
   module_name = self.to_s.underscore

    # Add in the module name    
    types.each { |type| type[:module] = module_name }
    
    # Create the fields class method
    cls = class << self; self; end
    cls.send(:define_method,:types) do
      types
    end
    
    # Generate the Hash
    type_hash_info = types.index_by { |type| type[:name] }
    
    # Generate the Hash class method
    cls.send(:define_method,:type_hash) do
      type_hash_info
    end
  
  end

  def self.register_publication_fields(fields_info)
  
   module_name = self.to_s.underscore

    # Add in the module name    
    fields_info.each { |field| field[:module] = module_name }
    
    # Create the fields class method
    cls = class << self; self; end
    cls.send(:define_method,:fields) do
      fields_info
    end
    
    # Generate the Hash
    fields_hash_info = fields_info.index_by { |field| field[:name] }
    
    # Generate the Hash class method
    cls.send(:define_method,:fields_hash) do
      fields_hash_info
    end
  
  end

end
