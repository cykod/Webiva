# Copyright (C) 2009 Pascal Rettig.

class Media::GalleryController < ParagraphController
  
  # Editor for galleries
  editor_header "Gallery Paragraphs", :paragraph_gallery
  
  editor_for :galleries, :name => 'Gallery List', :features => ['galleries']
                         
  editor_for :gallery, :name => 'Gallery View', :features => ['gallery'],
                       :inputs => [ [ :gallery_id, 'Gallery ID', :integer ], 
                                    [ :gallery_id, 'Image Gallery', :gallery ],
                                    [ :container, 'Gallery Container', :target] ]
                                   
  
  user_actions  :gallery_overlay
  
  class GalleriesOptions < HashModel
      default_options :detail_page => nil, :selected_galleries => [], :display_type => 'all', :images_per_page => 10
      
      validates_presence_of :detail_page
      validates_presence_of :display_type
  end
    
  def galleries
      @options = GalleriesOptions.new(params[:galleries] || @paragraph.data)
      
      if request.post?
        if @options.selected_galleries.is_a?(Array)
          @options.selected_galleries.collect! { |elem| elem.to_i } 
        end
	@options.detail_page = @options.detail_page.to_i
	@options.images_per_page = @options.images_per_page.to_i
        if @options.valid?
          @paragraph.data = @options.to_h
          @paragraph.save
          render_paragraph_update
          return
        end
      end      
      
      @pages = [['---Select Page---'.t,'']] + SiteNode.page_options("Site Root".t)
      
      @galleries = Gallery.find_select_options(:all,:order => 'name')
      
  end
  
  
 
  class GalleryOptions < HashModel
      default_options :gallery_id => nil, :images_per_page => 10,  :list_page => nil,:gallery_create => false,:gallery_category => nil,:description_string => 'Description',:autosort => 'no'

      integer_options :gallery_id,:list_page,:images_per_page
      boolean_options :gallery_create
      validates_numericality_of :images_per_page
  end
    
  
  def gallery_overlay
    @current_gallery = Gallery.find_by_id(params[:path][0])
    @images = @current_gallery.gallery_images.find(:all,:include => :domain_file)
    
    @image_info = render_to_string(:partial => 'gallery_image_info', :locals => { :images => @images, :gallery => @current_gallery })
    
    render :action => 'gallery_overlay'
    
  end
  
end
