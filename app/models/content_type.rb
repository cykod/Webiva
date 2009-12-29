# Copyright (C) 2009 Pascal Rettig.



class ContentType < DomainModel

  has_many :content_nodes
  has_many :content_node_values

  belongs_to :content_meta_type
  
  belongs_to :container, :polymorphic => true
  
  def after_destroy
    ContentNode.destroy_all({ :content_type_id => self.id })
  end

  def self.fetch(container_type,container_id)
    self.find_by_container_type_and_container_id(container_type,container_id)
  end

  def after_update
    self.content_node_values.delete
  end

  def name
    nm = ''
    nm << self.container_type.titleize.split(" ")[-1]  + " " if !self.container_type.blank? 
    nm + self.content_name
  end


  def content_link(obj)
    if !(path = self.detail_site_node_url).blank?
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
