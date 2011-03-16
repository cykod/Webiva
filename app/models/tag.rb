# Copyright (C) 2009 Pascal Rettig.


# Tags are used to tag users in the system with certain
# lables. Those labels can have descriptions. 
class Tag < DomainModel


  has_one :tag_note, :dependent => :destroy

  has_many :end_user_tags

  def after_create #:nodoc:
    self.create_tag_note()
  end

  def self.get_tag(tag_name)
    self.find_by_name(tag_name) || self.create(:name => tag_name)
  end

  def self.get_tag_cloud(sizes=[])
    tags = Tag.find(:all, :select => 'tags.name, tags.id, COUNT(tags.id) as cnt',
                    :joins => :end_user_tags, :order => 'tags.name', :group => 'tags.id')
    tags.collect do |tg|
      size = sizes.size < tg.cnt.to_i ? sizes[-1] : sizes[tg.cnt-1]
      { :name => tg.name, :count => tg.cnt, :id => tg.id, :size => size }
    end
  end
end
