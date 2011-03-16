# Copyright (C) 2009 Pascal Rettig.

class EndUserTag < DomainModel
  belongs_to :tag
  belongs_to :end_user
end
