# Copyright (C) 2009 Pascal Rettig.


# Tags are used to tag users in the system with certain
# lables. Those labels can have descriptions. 
class Tag < DomainModel


  has_one :tag_note, :dependent => :destroy

  has_many :end_user_tags

  def after_create #:nodoc:
    self.create_tag_note()
  end
end
