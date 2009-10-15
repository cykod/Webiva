# Copyright (C) 2009 Pascal Rettig.



module ModelExtension::ContentNodeExtension

  module ClassMethods
  
    def content_node(options = {})
      attr_accessor :content_node_skip
      after_save :content_node_save
      if !options[:skip_has_one]
        has_one :content_node, :as => :node, :dependent => :destroy
      end
      
      self.send(:include, ModelExtension::ContentNodeExtension::InstanceMethods)
      
      define_method(:content_node_options) do
        options
      end
    end
    
    def content_node_type(component,content_type,options = {})
      after_create :content_node_type_create
      
      has_one :content_type, :as => 'Container', :dependent => :destroy
      
      options = options.clone
      options[:component] = component.to_s
      options[:content_type] = content_type
      options.symbolize_keys!
      self.send(:include, ModelExtension::ContentNodeExtension::NodeTypeInstanceMethods)
      define_method(:content_node_type_options) do 
        options
      end
    end
    
  end
  
  def self.append_features(mod)
    super
    mod.extend ModelExtension::ContentNodeExtension::ClassMethods
  end
  
  module InstanceMethods

    def content_node_save
      # Only save if we aren't already inside of save_content
      save_content(nil,{},true) if(!content_node_skip)
    end
    
    def save_content(user,atr={},skip_save = false)
      self.attributes = atr 
      self.content_node_skip = true
      
      if skip_save || (saved_content = self.save)
        if !self.content_node_options[:except] || resolve_argument(self.content_node_options[:except],nil)
          cn = self.content_node || self.build_content_node
          cn.update_node_content(user,self,self.content_node_options)
        end
      end
      self.content_node_skip = false
      return skip_save || saved_content
    end
  end
  
  module NodeTypeInstanceMethods 
  
    def content_node_type_create
       opts = self.content_node_type_options
       
       title_field = (opts[:title_field] || 'name').to_s
       url_field = (opts[:url_field] || 'id').to_s
       
       # Get the name of the content
       content_name = self.resolve_argument(opts[:content_name],:name)
       content_type = resolve_argument(opts[:content_type])
       
       ContentType.create(:component => opts[:component],
                          :container => self, 
                          :content_name => content_name,
                          :content_type => content_type,
                          :title_field => title_field,
                          :url_field => url_field,
                          :search_results => opts[:search] )
    end
  end
  

end
