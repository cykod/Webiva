
module WordPressAudioPlayerHelper
  include EscapeHelper

  def render_word_press_audio_player_setup(swf_url, opts={})
    output = "AudioPlayer.setup('#{jh swf_url}'"
    output << ", #{opts.to_json}" if opts
    output << ");\n"
  end

  def render_word_press_audio_player_embed(container_id, sound_file, width=290, opts=nil)
    options = {:soundFile => sound_file, :width => width}
    options.merge!(opts) if opts

    audio_options = {}
    options = options.each do |key,value|
      if value.is_a?(FalseClass)
	audio_options[key] = 'no'
      elsif value.is_a?(TrueClass)
	audio_options[key] = 'yes'
      else
	audio_options[key] = value
      end
    end
    output = "AudioPlayer.embed('#{container_id}', #{audio_options.to_json});\n"
  end


  def render_word_press_audio_player_container(container_id, notice=nil)
    "<p id='#{container_id}' class='word-press-audio-player'>#{notice}</p>"
  end
end
