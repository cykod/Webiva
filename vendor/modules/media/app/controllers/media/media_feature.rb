class Media::MediaFeature < ParagraphFeature

  include SwfObjectHelper

  feature :media_media_video, :default_feature => <<-FEATURE
    <cms:wrapper>
      <cms:video/>
    </cms:wrapper>
  FEATURE

  def media_media_video_feature(data)
    webiva_feature(:media_media_video,data) do |c|
      c.define_tag('wrapper') { |t| "<div align='#{data[:options].align}'>#{t.expand}</div>" }
      c.define_tag('video') do |t|
	container_id = "#{data[:options].media_type}_#{paragraph.id}"
	data[:options].player.headers(self)
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
	container_id = "#{data[:options].media_type}_#{paragraph.id}"
	data[:options].player.headers(self)
	data[:options].player.render_player(container_id)
      end
    end
  end

  feature :media_media_swf, :default_feature => <<-FEATURE
    <cms:wrapper>
      <cms:swf/>
    </cms:wrapper>
   FEATURE

  def media_media_swf_feature(data)
    webiva_feature(:media_media_swf,data) do |c|
      c.define_tag('wrapper') { |t| "<div align='#{data[:options].align}'>#{t.expand}</div>" }
      c.define_tag('swf') do |t|
	container_id = "swf_#{paragraph.id}"
	<<-SWF
	#{self.render_swf_container(container_id)}
	<script type='text/javascript'>
	  #{self.render_swf_object(container_id, data[:options].swf_url, data[:options].flash_width, data[:options].flash_height, data[:options].flash_options)}
	</script>
	SWF
      end
    end
  end

end
