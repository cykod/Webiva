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
                  'Media Options' => { :action => 'options' },
                  'Video Options' => { :action => 'video_options' },
                  'Audio Options' => { :action => 'audio_options' }

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

  def video_options
    @options = self.class.video_options(params[:options])
    @options.default_options = true

    if @options.handler_info.nil?
      flash[:error] = 'Must set video handler first'
      return redirect_to :action => 'options'
    end

    cms_page_path ['Options','Modules','Media Options'], "#{@options.handler_info[:name]} Default Options"

    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated video options".t 
      redirect_to :action => 'options'
      return
    end    
  end

  def audio_options
    @options = self.class.audio_options(params[:options])
    @options.default_options = true

    if @options.handler_info.nil?
      flash[:error] = 'Must set audio handler first'
      return redirect_to :action => 'options'
    end

    cms_page_path ['Options','Modules','Media Options'], "#{@options.handler_info[:name]} Default Options"

    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated audio options".t 
      redirect_to :action => 'options'
      return
    end    
  end

  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end

  def self.video_options(vals=nil)
    vals = nil if vals && vals.length == 0
    Configuration.get_config_model(Media::MediaController::VideoOptions,vals)
  end

  def self.audio_options(vals=nil)
    vals = nil if vals && vals.length == 0
    Configuration.get_config_model(Media::MediaController::AudioOptions,vals)
  end

  class Options < HashModel
    include HandlerActions

    attributes :media_video_handler => 'media/players/video/flv_player',
      :media_audio_handler => 'media/players/audio/word_press_audio_player'

    validates_presence_of :media_video_handler, :media_audio_handler

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
