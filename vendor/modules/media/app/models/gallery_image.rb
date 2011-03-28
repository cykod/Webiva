# Copyright (C) 2009 Pascal Rettig.

class GalleryImage < DomainModel

  acts_as_list :scope => :gallery_id
  belongs_to :gallery, :counter_cache => 'image_count'
  has_domain_file  :domain_file_id

  after_destroy :remove_domain_file

  def remove_domain_file
    fl = self.domain_file
    fl.destroy if fl
  end 
end
