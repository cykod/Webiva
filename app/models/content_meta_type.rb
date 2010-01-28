

# ContentMetaType's is a container class for ContentType's
# that allow paragraphs to update the canonical content locations
# for specific content types
class ContentMetaType < DomainModel

  has_many :content_types
  serialize :category_value

  def after_save # :nodoc:

    # Need to update all content types that could have 
    # this as the meta type
    conditions = { :container_type => self.container_type,
                   :content_meta_type_id => nil
                 }
    if !self.category_field.blank?
      conditions[self.category_field.to_sym] = self.category_value
    end
    
    # 
    types = ContentType.find(:all,:conditions => conditions ) + self.content_types

    types.each do |content_type|
      if content_type.container
        if match_type(content_type)
          update_type(content_type)
          content_type.save if content_type.changed?
        else
          content_type.update_attributes(:content_meta_type_id => nil,
                                         :detail_site_node_url => nil,
                                         :list_site_node_url => nil)
        end
      end
   end
    
  end

  # Update the attributes of a content_type to match this content_meta_type
  def update_type(content_type)
    content_type.content_meta_type_id=self.id 
    if self.url_field
      url = self.detail_url + "/" + content_type.container.send(self.url_field)
      content_type.detail_site_node_url = url

      if !self.list_url.blank?
        list_url = self.list_url + "/" + content_type.container.send(self.url_field)
        content_type.list_site_node_url = url
      end
    else
      url = self.detail_url
      content_type.detail_site_node_url = url

      if !self.list_url.blank?
        list_url = self.list_url
        content_type.list_site_node_url = url
      end
    end
  end

  # Find out if this content_meta_type still matchs a specific content type
  def match_type(content_type)
    if content_type.container_type == self.container_type
      if self.category_field.blank?
        true
      else
        val = content_type.send(category_field)
        if category_value.is_a?(Array)
          category_value.include?(val)
        else
          category_value == val
        end
      end
    else
      false
    end
  end

  def self.generate(identity_hash,container_type,options={ })
    cmt = self.find_by_paragraph_hash(identity_hash)
    return cmt if cmt

    cmt = ContentMetaType.new(
                           :paragraph_hash => identity_hash,
                           :container_type => container_type,
                           :category_field => options[:category_field],
                           :category_value => options[:category_value],
                           :url_field => options[:url_field] ? options[:url_field].to_s : nil
                           )
  end

  
  def after_destroy # :nodoc:
    # Need to get rid of links and detail urls
    self.content_types.each do |content_type|
      content_type.update_attributes(:content_meta_type_id => nil,
                                    :detail_site_node_url => nil,
                                    :list_site_node_url => nil)
    end
  end
end
