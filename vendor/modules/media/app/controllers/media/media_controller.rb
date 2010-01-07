class Media::MediaController < ParagraphController

  editor_header 'Media Paragraphs'
  
  editor_for :video, :name => "Video", :feature => :media_media_video
  editor_for :audio, :name => "Audio", :feature => :media_media_audio
  editor_for :swf, :name => "Swf", :feature => :media_media_swf

  class BaseMediaOptions < HashModel
    attributes :media_file_id => nil, :align => 'center', :handler_data => {},
               :autoplay => false, :loop => false, :background_color => 'FFFFFF'

    integer_options :media_file_id
    boolean_options :autoplay, :loop

    validates_presence_of :media_file_id

    def alignment_options
      @alignment_options ||= %w( left center right )
    end

    def module_options
      @module_options ||= Media::AdminController.module_options
    end

    def media_file
      @media_file ||= DomainFile.find_by_id self.media_file_id
    end

    def valid_media?(file=nil)
      self.handler_info[:class].valid_media?(file)
    end

    def handler_options
      return @handler_options if @handler_options
      info = self.handler_info
      options_class_name = info[:class_name] + '::Options'
      options_class = options_class_name.constantize
      @handler_options = options_class.new(self.handler_data)
    end

    def handler_partial
      @handler_partial ||= self.handler_info[:partial]
    end

    def validate
      errors.add(:align) unless self.alignment_options.include?(self.align)

      errors.add(:background_color) unless self.background_color =~ /^[0-9A-F]{6}$/i

      if self.media_file_id
	errors.add(:media_file_id, 'missing') unless self.media_file
	if self.media_file
	  errors.add(:media_file_id, 'invalid type') unless self.valid_media?
	end
      end

      errors.add(:handler_data) unless self.handler_options.valid?
    end
  end

  class VideoOptions < Media::MediaController::BaseMediaOptions
    attributes :width => 320, :height => 240

    integer_options :width, :height

    validates_presence_of :width, :height

    def handler_info
      module_options.media_video_handler_info
    end

    def player
      @player ||= module_options.media_video_handler_instance(self)
    end
  end

  class AudioOptions < Media::MediaController::BaseMediaOptions
    def handler_info
      module_options.media_audio_handler_info
    end

    def player
      @player ||= module_options.media_audio_handler_instance(self)
    end
  end

  class SwfOptions < HashModel
    attributes :align => 'center', :swf_file_id => nil

    integer_options :swf_file_id

    validates_presence_of :swf_file_id

    def alignment_options
      @alignment_options ||= %w( left center right )
    end

    def swf
      @swf ||= DomainFile.find_by_id(self.swf_file_id)
    end

    def validate
      errors.add(:align) unless self.alignment_options.include?(self.align)

      if self.swf_file_id
	errors.add(:swf_file_id) unless self.swf
      end
    end
  end
end
