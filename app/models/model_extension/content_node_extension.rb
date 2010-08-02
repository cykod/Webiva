# Copyright (C) 2009 Pascal Rettig.



module ModelExtension::ContentNodeExtension

  module ClassMethods
  
    # See ContentNode for an overview of the content node system
    # and how to use this method
    #
    # Options:
    # 
    # [:skip_has_one]
    #   Skips the polymorphic has_one relationship with content_node 
    # [:except]
    #   symbol or proc the is resolved to determine whether or not to create a content node
    # [:container_type]
    #   string representing the class that is the ContentType container for this class
    # [:container_field]
    #   symbol with the name of the attribute that is the belong_to foreign key for the container
    # [:push_value]
    #   set to true to immediately push the content node value - should only be done for admin only content models
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
    
    # See ContentType for an overview of content types.
    # 
    # content_node_type will add any entry to the ContentType table every time
    # a new object of this class is created.
    #
    # content_type is a string representing the class to create content nodes
    # e.g. you could call content_type on a BookBook with a content_type of BookPage
    #
    # Options:
    #
    # [:except]
    #   symbol or proc that is resolved to determine whether or not to create a content type
    # [:title_field]
    #   field that represents the title of the content node (deafults to name)
    # [:url_field]
    #   field that represents the url of the content node (deafults to id)
    # [:content_name]
    #   name of the content type
    def content_node_type(component,content_type,options = {})
      after_create :content_node_type_create
      after_update :content_node_type_update
      
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
  
  def self.append_features(mod) #:nodoc:
    super
    mod.extend ModelExtension::ContentNodeExtension::ClassMethods
  end
  
  module InstanceMethods

    def content_node_link
      self.content_node.link if self.content_node
    end

    def content_node_save #:nodoc:
      # Only save if we aren't already inside of save_content
      save_content(nil,{},true) if(!content_node_skip)
    end
    
    # This is added to all content nodes, and should ideally be used
    # to save the object as it will record the last author into the content node
    # table (otherwise it is called automatically after save)
    def save_content(user,atr={},skip_save = false)
      self.attributes = atr 
      self.content_node_skip = true
      
      if skip_save || (saved_content = self.save)
        if !self.content_node_options[:except] || !resolve_argument(self.content_node_options[:except],nil)
          cn = self.content_node || self.build_content_node
          cn.update_node_content(user,self,self.content_node_options)
        end
      end
      self.content_node_skip = false
      return skip_save || saved_content
    end
  end
  
  module NodeTypeInstanceMethods  #:nodoc:all
  
    def content_node_type_create #:nodoc:

      if !self.content_node_type_options[:except] || !resolve_argument(self.content_node_type_options[:except],nil)

        opts = self.content_node_type_options
        
        title_field = (opts[:title_field] || 'name')
        url_field = (opts[:url_field] || 'id')

        title_field = title_field.call(self) if title_field.is_a?(Proc)
        url_field = url_field.call(self) if url_field.is_a?(Proc)
        
        # Get the name of the content
        content_name = self.resolve_argument(opts[:content_name],:name)
        content_type = resolve_argument(opts[:content_type])
        
        ContentType.create(:component => opts[:component],
                           :container => self, 
                           :content_name => content_name,
                           :content_type => content_type,
                           :title_field => title_field.to_s,
                           :url_field => url_field.to_s,
                           :search_results => opts[:search] )
      end
    end

    def content_node_type_update #:nodoc:
      opts = self.content_node_type_options

       # Get the name of the content
       content_name = self.resolve_argument(opts[:content_name],:name)

       if !self.content_type
        self.content_node_type_create
      elsif content_name != self.content_type.content_name
        self.content_type.update_attributes(:content_name => content_name)
      end

    end
  end
  

end
