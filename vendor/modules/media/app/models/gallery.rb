# Copyright (C) 2009 Pascal Rettig.

class Gallery < DomainModel

  validates_datetime :occurred_at

  acts_as_taggable :join_table => 'gallery_tags' 
  
  belongs_to :container, :polymorphic => true
  belongs_to :owner, :polymorphic => true
  
  has_domain_file :domain_file_id
  
  has_many :gallery_images,  :order => :position, :conditions => 'approved = 1', :include => :domain_file
  
  has_many :all_images, :class_name => 'GalleryImage', :dependent => :destroy, :order => :position
  has_one :first_image, :class_name => 'GalleryImage', :conditions => 'position = 1'
  
  def before_create
    if self.domain_file_id.blank?
      gallery_folder_id = Configuration.options.gallery_folder || DomainFile.root_folder.id
      gal_folder = DomainFile.create_folder(name,gallery_folder_id,:automatic => true,:special=>'gallery')
      self.domain_file = gal_folder
      
    end    
  end
  
  def after_destroy
    fl = self.domain_file
    fl.destroy if fl
  end 
  
  
  def resort_images(ascending=true)
    arr = self.gallery_images
    
    if ascending
      arr.sort! { |a,b| a.name.to_s <=> b.name.to_s }
    else
      arr.sort! { |a,b| b.name.to_s <=> a.name.to_s }
    end
    
    arr.each_with_index do |img,idx|
      img.update_attribute(:position,idx+1)
    end
  
  end
  
end
