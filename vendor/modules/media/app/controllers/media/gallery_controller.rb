# Copyright (C) 2009 Pascal Rettig.

class Media::GalleryController < ParagraphController
  
  # Editor for galleries
  editor_header "Gallery Paragraphs", :paragraph_gallery
  
  editor_for :galleries, :name => 'Gallery List', :features => ['galleries'], :inputs => {:input => [[ :container, 'Gallery Container', :target ]], :editor => [[ :edit_container, 'Edit Permission', :target ]] }
                         
  editor_for :gallery, :name => 'Gallery View', :features => ['gallery'],
                       :inputs => { :input => [ [ :gallery_id, 'Gallery ID', :integer ], 
                                                [ :gallery_id, 'Image Gallery', :gallery ],
                                                [ :container, 'Gallery Container', :target] ],
                                    :container => [  [ :container, 'Gallery Container', :target] ],
                                    :editor => [ [ :edit_container, 'Edit Permission', :target ] ] }

                                   
  
  user_actions  :gallery_overlay
  
  class GalleriesOptions < HashModel
      default_options :detail_page => nil, :selected_galleries => [], :display_type => 'all', :images_per_page => 10
      
      validates_presence_of :detail_page
      validates_presence_of :display_type

      integer_array_options :selected_galleries
  end
    
 
  class GalleryOptions < HashModel
      attributes :gallery_id => nil, :images_per_page => 10,  :list_page => nil,:gallery_create => false,:gallery_category => nil,:description_string => 'Description',:autosort => 'no', :include_javascript => true

      integer_options :gallery_id,:list_page,:images_per_page
      boolean_options :gallery_create, :include_javascript
      validates_numericality_of :images_per_page
  end
    
  
  def gallery_overlay
    @current_gallery = Gallery.find_by_id(params[:path][0])
    @images = @current_gallery.gallery_images.find(:all,:include => :domain_file)
    
    @image_info = render_to_string(:partial => 'gallery_image_info', :locals => { :images => @images, :gallery => @current_gallery })
    
    render :action => 'gallery_overlay'
    
  end
  
end
