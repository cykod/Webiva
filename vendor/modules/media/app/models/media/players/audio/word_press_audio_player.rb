
class Media::Players::Audio::WordPressAudioPlayer < Media::Players::Audio::Base

  include WordPressAudioPlayerHelper

  def self.media_audio_handler_info
    {
      :name => 'Word Press Audio Player',
      :partial => 'word_press_audio_player_options',
      :defaults_partial => 'word_press_audio_player_default_options'
    }
  end

  def component_path ; '/components/media/audio-player'; end
  def swf_url ; "#{self.component_path}/player.swf"; end

  def sound_file
    @options.media_file.full_url if @options.media_file
  end

  def headers(renderer)
    renderer.require_js "#{self.component_path}/audio-player-uncompressed.js"

    output = "<script type='text/javascript'>\n";
    output << self.render_word_press_audio_player_setup(self.swf_url)
    output << "</script>\n";

    renderer.html_include('extra_head_html',output)
  end

  def render_player(container_id)
    return 'Audio file not set' unless @options.media_file

    output = self.render_word_press_audio_player_container(container_id)
    output << "\n<script type='text/javascript'>\n";
    output << self.render_word_press_audio_player_embed(container_id, self.sound_file, @options.handler_options.width, self.audio_player_options)
    output << "</script>\n";
  end

  def self.valid_media?(file)
    Media::Players::Audio::Base.valid_media? file
  end

  def audio_player_options
    options = @options.handler_options.to_h
    options.delete(:width)
    options[:initialvolume] = options.delete(:volume).to_i
    options[:autostart] = @options.autoplay
    options[:loop] = @options.loop
    options[:noinfo] = @options.handler_options.titles ? false : true
    options
  end

  class Options < HashModel
    attributes :width => 290, :titles => nil, :artists => nil,
               :animation => false, :remaining => false, :volume => 60,
               :buffer => 5, :encode => false, :checkpolicy => false, :rtl => false,
               :transparentpagebg => true, :pagebg => nil,
               :bg => 'E5E5E5', :leftbg => 'CCCCCC', :lefticon => '333333', :voltrack => 'F2F2F2',
               :volslider => '666666', :rightbg => 'B4B4B4', :rightbghover => '999999', :righticon => '333333',
               :righticonhover => 'FFFFFF', :loader => '009900', :track => 'FFFFFF',
               :tracker => 'DDDDDD', :border => 'CCCCCC', :skip => '666666', :text => '333333'

    validates_presence_of :width, :volume, :bg, :leftbg, :lefticon, :voltrack, :volslider, :rightbg,
                          :rightbghover, :righticon, :righticonhover, :loader, :track, :tracker, :border, :skip, :text

    boolean_options :animation, :remaining, :noinfo, :encode, :checkpolicy, :rtl, :transparentpagebg

    validates_numericality_of :volume, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 100

    def width_options
      @width_options ||= [290, '100%']
    end

    def volume_options
      @volume_options ||= (0..10).to_a.map { |n| [n, n*10] }
    end

    def volume
      @volume.to_i
    end

    def width
      return @width if @width.to_s == '100%'
      @width.to_i
    end

    def validate
      [:bg, :leftbg, :lefticon, :voltrack,
       :volslider, :rightbg, :rightbghover, :righticon,
       :righticonhover, :loader, :track,
       :tracker, :border, :skip, :text].each do |attr|
	color = self.send(attr)
	if color
	  errors.add(attr, 'invalid color') unless color =~ /^[0-9A-F]{6}$/i
	end
      end

      errors.add(:width) unless self.width_options.include?(self.width)

      if ! self.transparentpagebg
	errors.add(:pagebg, 'invalid color') unless self.pagebg =~ /^[0-9A-F]{6}$/i
      end

      true
    end
  end
end
