# Copyright (C) 2009 Pascal Rettig.


class ContentNode < DomainModel

  belongs_to :node, :polymorphic => true, :dependent => :destroy
  belongs_to :author,:class_name => 'EndUser',:foreign_key => 'author_id'
  belongs_to :content_type
  
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

end
