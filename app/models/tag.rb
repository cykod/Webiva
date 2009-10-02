# Copyright (C) 2009 Pascal Rettig.

class Tag < DomainModel


  has_one :tag_note, :dependent => :destroy

  has_many :end_user_tags

  def after_create
    self.create_tag_note()
  end
end
