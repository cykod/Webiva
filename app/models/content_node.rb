# Copyright (C) 2009 Pascal Rettig.


class ContentNode < DomainModel

  belongs_to :node, :polymorphic => true #, :dependent => :destroy
  belongs_to :author,:class_name => 'EndUser',:foreign_key => 'author_id'
  belongs_to :content_type
  has_many :content_node_values
  
  def update_node_content(user,item,opts={})
    opts = opts.symbolize_keys
    if self.content_type_id.blank?
      if opts[:container_type] # If there is a container field
        container_type = opts.delete(:container_type)
        container_id = item.send(opts.delete(:container_field))
        self.content_type = ContentType.find_by_container_type_and_container_id(container_type,container_id)
      else
        self.content_type = ContentType.find_by_content_type(item.class.to_s)
      end
    end

    
    opts.slice(:published,:sticky,:promoted,:content_url_override).each do |key,opt|
      val = item.resolve_argument(opt)
      val = false if val.blank?
      self.send("#{key}=",val)
    end

    self.updated_at = Time.now
    
    if opts[:user_id]
      user_id = item.resolve_argument(opts[:user_id])
    elsif item.respond_to?(:content_node_user_id)
      user_id = item.content_node_user_id(user)
    else
      user_id = user.id if user
    end
    
    if self.new_record?
      self.author_id = user_id if user_id
    else 
      self.last_editor_id = user_id if user_id
    end
    self.save
  end


  def admin_url
    if self.content_type
      if self.content_type.container
        self.content_type.container.content_admin_url(self.node_id)
      else
        cls =self.content_type.content_type.constantize
        cls.content_admin_url(self.node_id)
      end
    else
      nil
    end
  end

  # Generate a content_node_value 
  # used in search results
  def generate_content_values!(type_preload = nil)
    return unless node
    # Don't want to have to reload the type for each 
    # node we're created
    type_preload ||= self.content_type

    Configuration.languages.each do |lang|
      cnv = content_node_values.find_by_language(lang) || content_node_values.build(:language => lang,:content_type_id => self.content_type_id)

      # If we haven't updated this since we last updated the
      # content node value, just return
      if !cnv.updated_at || self.updated_at > cnv.updated_at
        if(self.node.respond_to?(:content_node_body))
          cnv.body = Util::TextFormatter.text_plain_generator( node.content_node_body(lang))
        else
          cnv.body =Util::TextFormatter.text_plain_generator( node.attributes.values.select { |val| val.is_a?(String) }.join("\n\n") )
        end
        
        if type_preload
          cnv.title = node.send(content_type.title_field)
          cnv.link = self.content_url_override || type_preload.content_link(node)
        else
          cnv.title = node.name
          cnv.link = self.content_url_override || nil
        end
        cnv.save
      end
    end
  end

  def content_description(language)
    if self.node.respond_to?(:content_description)
      self.node.content_description(language)
    else
      nil
    end
  end


  def self.search(language,query,options = { })
    search_handler = Configuration.options.search_handler

    # Run an internal mysql fulltext search if the handler is blank
    if !search_handler.blank? &&  handler_info = get_handler_info(:webiva,:search,search_handler)
      handler_info[:class].search(language,query,options)
    else
      internal_search(language,query,options)
    end
  end

  def self.internal_search(language,query,options = { })
    ContentNodeValue.search language, query, options
  end
end
