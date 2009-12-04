# Copyright (C) 2009 Pascal Rettig.



class ContentType < DomainModel

  has_many :content_nodes
  
  belongs_to :container, :polymorphic => true
  
  belongs_to :detail_site_node, :class_name => 'SiteNode',:foreign_key => 'detail_site_node_id'
  belongs_to :list_site_node, :class_name => 'SiteNode',:foreign_key => 'list_site_node_id'
  
  def after_destroy
    ContentNode.destroy_all({ :content_type_id => self.id })
  end
end
