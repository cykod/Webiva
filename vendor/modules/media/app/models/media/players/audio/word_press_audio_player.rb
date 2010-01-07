
class Media::Players::Audio::WordPressAudioPlayer < Media::Players::Audio::Base

  def self.media_audio_handler_info
    {
      :name => 'Word Press Audio Player',
      :partial => nil
    }
  end

  def render(container_id)
  end

  def self.valid_media?(file)
    true
  end

  class Options < HashModel
  end
end
