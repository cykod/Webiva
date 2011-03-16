# Copyright (C) 2009 Pascal Rettig.

class ContentTag < DomainModel

  has_many :content_tag_tags

  def self.get_tag(content_type,tag_name)
    self.find_by_content_type_and_name(content_type,tag_name) ||
      self.create(:content_type => content_type,:name => tag_name)
  end
  
  def self.get_tag_cloud(class_name,sizes = [])
    content_tags = ContentTag.find(:all,:conditions => [ 'content_tags.content_type=? AND content_tag_tags.content_tag_id=content_tags.id',class_name],
                    :select => 'content_tags.name as name, content_tags.id, COUNT(content_tag_tags.id) as cnt',
                    :joins => :content_tag_tags,:order => 'content_tags.name',:group => 'content_tags.id')
    content_tags.collect do |tg|
      size = sizes.size < tg.cnt.to_i ? sizes[-1] : sizes[tg.cnt.to_i-1]
      { :name => tg.name, :count => tg.cnt, :id => tg.id, :size => size }
    end
  end

end
