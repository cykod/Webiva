# Copyright (C) 2009 Pascal Rettig.

class Media::AdminController < ModuleController
  permit 'media_admin'

  component_info 'Media', :description => 'Media Support: Add Galleries, Flash and other media', 
                              :access => :public
                              
  # Register a handler feature
  register_handler :model, :domain_file, "Media::FileExtensions", :actions => [ :after_destroy, :after_create ] 
  
  register_permission_category :gallery, "Gallery" ,"Permissions Related to Gallery Functionality"
  
  register_permissions :gallery, [ [ :create_galleries, 'Create Galleries', 'Whether a user can create and delete galleries'],
                                [ :edit_galleries, 'Edit Galleries', 'Whether a user edit and delete images in all galleries'],
                                [ :upload_to_galleries, 'Upload Images', 'Can a user upload to all galleries']
                              ]

  content_model :galleries

  protected
  def self.get_galleries_info
      [
      {:name => "Galleries",:url => { :controller => '/media/manage/galleries' } ,:permission => 'gallery_edit_galleries', :icon => 'icons/content/photogallery.gif' }
      ]
  end

end
