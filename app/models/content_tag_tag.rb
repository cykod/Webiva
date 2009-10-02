# Copyright (C) 2009 Pascal Rettig.

class ContentTagTag < DomainModel
  belongs_to :content_tag
  belongs_to :content, :polymorphic => true
end
