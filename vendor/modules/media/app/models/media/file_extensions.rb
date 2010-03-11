# Copyright (C) 2009 Pascal Rettig.


class Media::FileExtensions  < DomainModelExtension


  def after_destroy(df)
    if df.file_type == 'fld'
      Gallery.destroy_all(['domain_file_id=?',df.id])
    else
      GalleryImage.destroy_all(['domain_file_id=?',df.id])
    end
  end  

  def after_create(df)
    if df.parent && df.parent.special == 'gallery'
      gal = Gallery.find_by_domain_file_id(df.parent.id)

      gal.gallery_images.create(:domain_file_id => df.id) if gal
    end  
  end

end
