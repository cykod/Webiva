# Copyright (C) 2009 Pascal Rettig.

class GalleryImage < DomainModel

  acts_as_list :scope => :gallery_id
  belongs_to :gallery, :counter_cache => 'image_count'
  belongs_to :domain_file
  
  def after_destroy
    fl = self.domain_file
    fl.destroy if fl
  end 
  
end
