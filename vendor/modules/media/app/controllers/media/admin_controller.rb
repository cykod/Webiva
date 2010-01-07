# Copyright (C) 2009 Pascal Rettig.

class Media::AdminController < ModuleController
  permit 'media_admin'

  component_info 'Media', :description => 'Media Support: Add Galleries, Flash and other media', 
                              :access => :public
                              
  # Register a handler feature
  register_handler :model, :domain_file, "Media::FileExtensions", :actions => [ :after_destroy, :after_create ] 
  register_handler :media, :video, 'Media::Players::Video::FlvPlayer'
  register_handler :media, :audio, 'Media::Players::Audio::WordPressAudioPlayer'

  register_permission_category :gallery, "Gallery" ,"Permissions Related to Gallery Functionality"
  
  register_permissions :gallery, [ [ :create_galleries, 'Create Galleries', 'Whether a user can create and delete galleries'],
                                [ :edit_galleries, 'Edit Galleries', 'Whether a user edit and delete images in all galleries'],
                                [ :upload_to_galleries, 'Upload Images', 'Can a user upload to all galleries']
                              ]

  content_model :galleries

  cms_admin_paths "options",
                  'Content' => { :controller => '/content' },
                  'Options' =>   { :controller => '/options' },
                  'Modules' =>  { :controller => '/modules' },
                  'Media Options' => { :action => 'options' }

  protected
  def self.get_galleries_info
      [
      {:name => "Galleries",:url => { :controller => '/media/manage/galleries' } ,:permission => 'gallery_edit_galleries', :icon => 'icons/content/photogallery.gif' }
      ]
  end

  public

  def options
    cms_page_path ['Options','Modules'], 'Media Options'

    @options = self.class.module_options(params[:options])

    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated media module options".t 
      redirect_to :controller => '/modules'
      return
    end    
  end

  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end

  class Options < HashModel
    include HandlerActions

    attributes :media_video_handler => nil, :media_audio_handler => nil

    def media_video_handlers
      @media_video_handlers ||= self.get_handler_options(:media, :video, true)
    end

    def media_audio_handlers
      @media_audio_handlers ||= self.get_handler_options(:media, :audio, true)
    end

    def media_video_handler_info
      @media_video_handler_info ||= self.get_handler_info(:media, :video, self.media_video_handler, true)
    end

    def media_audio_handler_info
      @media_audio_handler_info ||= self.get_handler_info(:media, :audio, self.media_audio_handler, true)
    end

    def media_video_handler_instance(args)
      self.get_handler_instance(:media, :video, self.media_video_handler, args)
    end

    def media_audio_handler_instance(args)
      self.get_handler_instance(:media, :audio, self.media_audio_handler, args)
    end

    def validate
      errors.add(:media_video_handler) unless self.get_handler_info(:media, :video, self.media_video_handler, true)
      errors.add(:media_audio_handler) unless self.get_handler_info(:media, :audio, self.media_audio_handler, true)
    end
  end
end
