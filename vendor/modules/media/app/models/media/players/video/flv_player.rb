
class Media::Players::Video::FlvPlayer < Media::Players::Video::Base

  include SwfObjectHelper

  def self.media_video_handler_info
    {
      :name => 'FLV Player',
      :partial => 'flvplayer_options',
      :defaults_partial => 'flvplayer_default_options'
    }
  end

  def render_player(container_id)
    output = self.render_swf_container(container_id)
    output << "<script type='text/javascript'>\n";
    output << self.render_swf_object(container_id, self.swf_url, self.flash_width, self.flash_height, self.flash_options)
    output << "</script>\n";
  end

  def component_path ; '/components/media/flvplayer'; end
  def swf_url ; "#{self.component_path}/flvplayer.swf"; end

  def flash_width
    @options.width.to_i + 6
  end

  def flash_height
    @options.height.to_i + 38
  end

  def flash_options
    { :flash_version => 9,
      :flash_vars => self.flash_vars,
      :flash_params => self.flash_params
    }
  end

  def flash_vars
    return @flash_vars if @flash_vars
    @flash_vars = { :contentpath => '',
                    :playerpath => self.component_path,
                    :skin => @options.handler_options.skin,
                    :skincolor => @options.handler_options.skincolor,
                    :skinscalemaximum => @options.handler_options.skinscalemaximum,
                    :autoscale => @options.handler_options.autoscale,
                    :smoothing => @options.handler_options.smoothing,
                    :autoplay => @options.autoplay,
                    :loop => @options.loop,
                    :buttonoverlay => @options.handler_options.buttonoverlay,
                    :preloader => @options.handler_options.preloader,
                    :ending => @options.handler_options.ending
                  }

    if ! @options.handler_options.autoscale
      @flash_vars[:videowidth] = @options.width
      @flash_vars[:videoheight] = @options.height
    end

    @flash_vars[:volume] = @options.handler_options.volume.to_f / 100.0
    @flash_vars[:video] = @options.media_file.full_url if @options.media_file
    @flash_vars[:preview] = @options.handler_options.preview ? @options.handler_options.preview.url : Configuration.domain_link("#{self.component_path}/defaultpreview.jpg")
    @flash_vars[:preroll] = @options.handler_options.preroll.full_url if @options.handler_options.preroll
    @flash_vars[:captions] = @options.handler_options.preroll.full_url if @options.handler_options.captions

    @flash_vars
  end

  def flash_params
    return @flash_params if @flash_params
    @flash_params = { :allowfullscreen => 'true',
                      :scale => 'noscale',
                      :salign => 'tl'
                    }
  end

  def self.valid_media?(file)
    Media::Players::Video::Base.valid_media? file
  end

  class Options < HashModel
    attributes :skin => 'defaultskin.swf', :color => '555555', :skinscalemaximum => 1, :volume => 100,
               :preview_file_id => nil, :preroll_file_id => nil, :captions_file_id => nil,
               :autoscale => false, :smoothing => true,
               :buttonoverlay => 'defaultbuttonoverlay.swf', :preloader => 'defaultpreloader.swf', :ending => 'defaultending.swf'

    integer_options :preview_file_id, :preroll_file_id, :captions_file_id, :volume
    boolean_options :autoscale, :smoothing

    validates_numericality_of :volume, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100

    def skin_scale_maximum_options
      @skin_scale_maximum_options ||= [1, 2, 3, 4.5]
    end

    def volume_options
      @volume_options ||= [['No Sound', 0], ['Low', 25], ['Medium', 50], ['Medium High', 75], ['High', 100]]
    end

    def preroll
      @preroll ||= DomainFile.find_by_id self.preroll_file_id
    end

    def preview
      @preview ||= DomainFile.find_by_id self.preview_file_id
    end

    def captions
      @captions ||= DomainFile.find_by_id self.captions_file_id
    end

    def volume
      @volume.to_i
    end

    def skinscalemaximum
      @skinscalemaximum.to_f
    end

    def skincolor
      "0x#{self.color}"
    end

    def skin_options
      @skin_options ||= self.get_file_options('vendor/modules/media/public/flvplayer/skins')
    end

    def buttonoverlay_options
      @buttonoverlay_options ||= self.get_file_options('vendor/modules/media/public/flvplayer/buttonoverlays')
    end

    def preloader_options
      @preloader_options ||= self.get_file_options('vendor/modules/media/public/flvplayer/preloaders')
    end

    def ending_options
      @ending_options ||= self.get_file_options('vendor/modules/media/public/flvplayer/endings')
    end

    def get_file_options(folder, file_type='swf')
      options = []
      Dir.glob("#{folder}/*.#{file_type}") do |file|
	file.sub!("#{folder}/", '')
	name = file.sub(".#{file_type}", '').gsub('-', ' ').titleize
	name = 'Default' if name =~ /^Default/
	options.unshift [name, file]
      end
      options
    end

    def validate
      if ! self.color.blank?
	errors.add(:color, 'invalid (must be in hex)') unless self.color =~ /^[0-9A-F]{6}$/i
      end

      errors.add(:skin) unless self.skin_options.rassoc(self.skin)
      errors.add(:buttonoverlay) unless self.buttonoverlay_options.rassoc(self.buttonoverlay)
      errors.add(:preloader) unless self.preloader_options.rassoc(self.preloader)
      errors.add(:ending) unless self.ending_options.rassoc(self.ending)
      errors.add(:skinscalemaximum) unless self.skin_scale_maximum_options.include?(self.skinscalemaximum)

      if self.preroll_file_id
	errors.add(:preroll_file_id, 'missing') unless self.preroll
	if self.preroll
	  errors.add(:preroll_file_id, 'invalid type') unless self.valid_media?(self.preroll)
	end
      end

      if self.preview_file_id
	errors.add(:preview_file_id, 'missing') unless self.preview
	if self.preview
	  errors.add(:preview_file_id, 'invalid type') unless self.preview.image?
	end
      end

      if self.captions_file_id
	errors.add(:captions_file_id) unless self.captions

	if self.captions
	  errors.add(:captions_file_id, 'invalid captions file (must be xml file in "Timed Text" format)') unless self.captions.mime_type == 'application/xml'
	end
      end
    end

  end

end
