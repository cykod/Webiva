# Copyright (C) 2009 Pascal Rettig.

=begin rdoc
ContentType's are containers for ContentNode's and allow ContentNode's
to be created and indexed correctly. ContentType's are linked to specific
locations on the front end of the website and so they allow ContentNode's
to know where their canonical location is

=== Using ContentType

ContentType's are created one of two ways, most commonlly by using the 
ModelExtension::ContentNodeExtension::ClassMethods#content_node_type method
which is available in all DomainModel's.

For example:
 
    content_node_type :book, "BookPage", 
           :content_name => :name,
           :title_field => :name, :url_field => :url

This appears in the BookBook class inside of the Book module. What this does is
create a ContentType that is a container for BookPage's. The name of the ContentType
will be automatically updated from the :name field of the ContentType and the 
system will use the :name field of BookPage as the name field for any ContentNodes
and the :url field of BookPage for the url location.

ModuleController also has a content_node_type class method that can be called inside of
a modules AdminController's to create a content type that doesn't have a container type. 
(For example a Poll might create content nodes for each poll, but not have a container 
DomainModel for each poll) 

=end
class ContentType < DomainModel

  has_many :content_nodes, :dependent => :destroy
  has_many :content_node_values, :dependent => :destroy

  belongs_to :content_meta_type
  
  belongs_to :container, :polymorphic => true
  
  def after_destroy #:nodoc:
    ContentNode.destroy_all({ :content_type_id => self.id })
  end

  # Find a content type by container and id
  def self.fetch(container_type,container_id)
    self.find_by_container_type_and_container_id(container_type,container_id)
  end

  def before_create #:nodoc:
    cmts = ContentMetaType.find(:all)
    cmts.each do |cmt|
      if(cmt.match_type(self))
        cmt.update_type(self)
        break
      end
    end
  end

  def after_update #:nodoc:
    self.content_node_values.clear
  end

  # Full name of this content type
  def name
    nm = ''
    nm << self.container_type.titleize.split(" ")[-1]  + " " if !self.container_type.blank? 
    nm + self.content_name
  end

  def type_description
    if self.container
      if self.container.respond_to?(:content_type_description)
	self.container.content_type_description
      else
	self.container_type.titleize.split(" ")[-1]
      end
    else
      ''
    end
  end

  # Link for a specific piece of content
  def content_link(obj)
    if !(path = self.detail_site_node_url).blank? && path != "#"
      if self.container && self.container.respond_to?(:content_detail_link_url)
        self.container.content_detail_link_url(path,obj)
      else
        val = obj.send(url_field).to_s
        SiteNode.link(path,val)
      end
    elsif !(path = self.list_site_node_url).blank?
      path
    else
      nil
    end
  end

  # Call to update the search index for this site
  # will automatically update any update nodes
  def self.full_site_index
    Configuration.put('index_last_update',nil)
    self.update_site_index(true)
  end

  def self.update_site_index(force=false)

    last_update = Configuration.get('index_last_update',nil)
    current_update = Time.now
    
    content_types = ContentType.find(:all).index_by(&:id)

    if (last_update)
      conditions =  ["updated_at > ?",last_update]
    else
      conditions = "1"
    end

    ContentNode.find_each(:conditions => conditions) do |content_node|
      content_node.generate_content_values!(content_types[content_node.content_type_id],false)
    end

    Configuration.put('index_last_update',current_update)
  end
end
