class Media::MediaController < ParagraphController

  editor_header 'Media Paragraphs'
  
  editor_for :video, :name => "Video", :feature => :media_media_video
  editor_for :audio, :name => "Audio", :feature => :media_media_audio
  editor_for :swf, :name => "Swf", :feature => :media_media_swf

  class BaseMediaOptions < HashModel
    attributes :media_file_id => nil, :align => 'center', :handler_data => {},
               :autoplay => false, :loop => false

    integer_options :media_file_id
    boolean_options :autoplay, :loop

    validates_presence_of :media_file_id, :unless => :default_options

    def default_options
      @default_options
    end

    def default_options=(default_options)
      @default_options = default_options
    end

    def alignment_options
      @alignment_options ||= %w( left center right )
    end

    def module_options
      @module_options ||= Media::AdminController.module_options
    end

    def media_file
      @media_file ||= DomainFile.find_by_id self.media_file_id
    end

    def media_file=(file)
      @media_file = file
    end

    def valid_media?(file=nil)
      self.handler_info[:class].valid_media?(file)
    end

    def handler_options
      return @handler_options if @handler_options
      default_handler_data = Media::AdminController.send("#{self.media_type}_options").handler_data
      @handler_options = self.handler_class.new( default_handler_data.deep_merge(self.handler_data) )
    end

    def handler_partial
      @handler_partial ||= self.handler_info[:partial]
    end

    def handler_defaults_partial
      @handler_defaults_partial ||= self.handler_info[:defaults_partial]
    end

    def handler_class
      "#{self.handler_info[:class_name]}::Options".constantize
    end

    def validate
      errors.add(:align) unless self.alignment_options.include?(self.align)

      if self.media_file_id
	errors.add(:media_file_id, 'missing') unless self.media_file
	if self.media_file
	  errors.add(:media_file_id, 'invalid type') unless self.valid_media? self.media_file
	end
      end

      if self.handler_options.valid?
	self.handler_data = self.handler_class.new(self.handler_data).to_passed_hash
      else
	errors.add(:handler_data)
      end
    end
  end

  class VideoOptions < Media::MediaController::BaseMediaOptions
    attributes :width => 320, :height => 240

    integer_options :width, :height

    validates_presence_of :width, :height

    def media_type ; 'video' ; end

    def handler_info
      module_options.media_video_handler_info
    end

    def player
      @player ||= module_options.media_video_handler_instance(self)
    end
  end

  class AudioOptions < Media::MediaController::BaseMediaOptions
    def media_type ; 'audio' ; end

    def handler_info
      module_options.media_audio_handler_info
    end

    def player
      @player ||= module_options.media_audio_handler_instance(self)
    end
  end

  class SwfOptions < HashModel
    attributes :align => 'center', :swf_file_id => nil, :width => nil, :height => nil,
               :play => true, :loop => false, :quality => 'high', :bgcolor => nil,
               :flash_align => nil, :salign => nil, :menu => true, :wmode => 'transparent',
               :flash_vars => nil, :scale => nil

    integer_options :swf_file_id
    boolean_options :play, :loop, :menu

    validates_presence_of :swf_file_id, :width, :height

    def alignment_options
      @alignment_options ||= %w( left center right ).map { |a| [a.titleize, a] }
    end

    def flash_align_options
      @flash_align_options ||= [['Not Set', nil], ['Left', 'l'], ['Right', 'r'], ['Top', 't'], ['Bottom', 'b']]
    end

    def salign_options
      @salign_options ||= self.flash_align_options + [['Top Left', 'tl'], ['Top Right', 'tr'], ['Bottom Left', 'bl'], ['Bottom Right', 'br']]
    end

    def quality_options
      @quality_options ||= %w(low high autolow autohigh best).map { |q| [q.titleize, q] }
    end

    def wmode_options
      @wmode_options ||= [['Window', 'window'], ['Opaque', 'opaque'], ['Transparent', 'transparent']]
    end

    def swf
      @swf ||= DomainFile.find_by_id(self.swf_file_id)
    end

    def scale_options
      @scale_options ||= [['Not Set', nil], ['Show all', 'showall'], ['No border', 'noborder'], ['Exact fit', 'exactfit'], ['No scale', 'noscale']]
    end

    def swf_url
      self.swf.url if self.swf
    end

    def flash_width
      self.width
    end

    def flash_height
      self.height
    end

    def flash_vars_hash
      return @flash_vars_hash if @flash_vars_hash

      @flash_vars_hash = {}
      self.flash_vars.split("\n").each do |line|
	key, value = line.split('=', 2)
	@flash_vars_hash[key] = value
      end if ! self.flash_vars.blank?

      @flash_vars_hash
    end

    def flash_options
      opts = self.to_h
      opts[:align] = opts.delete(:flash_align)
      opts.delete(:swf_file_id)
      opts.delete(:width)
      opts.delete(:height)
      opts.delete(:flash_vars)
      opts.delete_if { |key, value| value.nil? || value == '' }

      {:flash_params => opts,
       :flash_vars => self.flash_vars_hash
      }
    end

    def validate
      errors.add(:align) unless self.alignment_options.rassoc(self.align)
      errors.add(:flash_align) unless self.flash_align_options.rassoc(self.flash_align) if ! self.flash_align.blank?
      errors.add(:salign) unless self.salign_options.rassoc(self.salign) if ! self.salign.blank?
      errors.add(:quality) unless self.quality_options.rassoc(self.quality)
      errors.add(:wmode) unless self.wmode_options.rassoc(self.wmode)
      errors.add(:scale) unless self.wmode_options.rassoc(self.scale) if ! self.scale.blank?

      if ! self.bgcolor.blank?
	errors.add(:bgcolor) unless self.bgcolor =~ /^[0-9A-F]{6}$/i
      end

      if self.width
	errors.add(:width) unless self.width =~ /^\d+%?$/
      end

      if self.height
	errors.add(:height) unless self.height =~ /^\d+%?$/
      end

      if self.swf_file_id
	errors.add(:swf_file_id) unless self.swf
      end
    end
  end




  user_actions  [ :images, :image_gallery ]

  def images
      @gallery = Gallery.find_by_id_and_private_gallery(params[:path][0],false)
      if @gallery
        @gallery_images = @gallery.gallery_images.find(:all,:include => :domain_file) 
      else
        @gallery_image = []
      end
  end
  
  def image_gallery
      @gallery = Gallery.find_by_id_and_private_gallery(params[:path][0],false)
      @gallery_images = @gallery.gallery_images.find(:all,:include => :domain_file)
      
      render :action => 'image_gallery'
  end
end
