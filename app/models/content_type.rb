# Copyright (C) 2009 Pascal Rettig.



class ContentType < DomainModel

  has_many :content_nodes
  
  belongs_to :container, :polymorphic => true
  
  belongs_to :detail_site_node, :class_name => 'SiteNode',:foreign_key => 'detail_site_node_id'
  belongs_to :list_site_node, :class_name => 'SiteNode',:foreign_key => 'list_site_node_id'
  
  def after_destroy
    ContentNode.destroy_all({ :content_type_id => self.id })
  end

  def name
    nm = ''
    nm << self.container_type.titleize.split(" ")[-1]  + " " if !self.container_type.blank? 
    nm + self.content_name
  end


  def content_link(obj)
    if self.detail_site_node
      path =self.detail_site_node.node_path
      if self.container && self.container.respond_to?(:content_detail_link_url)
        self.container.content_detail_link_url(path,obj)
      else
        val = obj.send(url_field).to_s
        "#{path}/#{val}"
      end
    else
      nil
    end
  end

  def self.update_site_index

    last_update = Configuration.get('index_last_update',nil)
    current_update = Time.now
    
    content_types = ContentType.find(:all).index_by(&:id)

    if (last_update)
      conditions =  ["updated_at > ?",last_update]
    else
      conditions = "1"
    end

    ContentNode.find_each(:conditions => conditions) do |content_node|
      content_node.generate_content_values!(content_types[content_node.content_type_id])
    end

    Configuration.put('index_last_update',current_update)
  end
end
