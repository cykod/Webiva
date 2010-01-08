class Media::MediaFeature < ParagraphFeature

  feature :media_media_video, :default_feature => <<-FEATURE
    <cms:wrapper>
      <cms:video/>
    </cms:wrapper>
  FEATURE

  def media_media_video_feature(data)
    webiva_feature(:media_media_video,data) do |c|
      c.define_tag('wrapper') { |t| "<div align='#{data[:options].align}'>#{t.expand}</div>" }
      c.define_tag('video') do |t|
	container_id = "video_#{paragraph.id}"
	data[:options].player.render_player(container_id)
      end
    end
  end

  feature :media_media_audio, :default_feature => <<-FEATURE
    <cms:wrapper>
      <cms:audio/>
    </cms:wrapper>
  FEATURE

  def media_media_audio_feature(data)
    webiva_feature(:media_media_audio,data) do |c|
      c.define_tag('wrapper') { |t| "<div align='#{data[:options].align}'>#{t.expand}</div>" }
      c.define_tag('audio') do |t|
	container_id = "audio_#{paragraph.id}"
	data[:options].player.render_player(container_id)
      end
    end
  end

  feature :media_media_swf, :default_feature => <<-FEATURE
    Swf Feature Code...
  FEATURE

  def media_media_swf_feature(data)
    webiva_feature(:media_media_swf,data) do |c|
      c.define_tag('wrapper') { |t| "<div align='#{data[:options].align}'>#{t.expand}</div>" }
      c.define_tag('swf') { |t| '' }
    end
  end

end
