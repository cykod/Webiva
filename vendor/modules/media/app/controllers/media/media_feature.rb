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
	player = data[:options].player
	container_id = "video_#{paragraph.id}"
	output = self.render_swf_container(container_id)
	output << "<script type='text/javascript'>\n";
	output << self.render_swf_object(container_id, player.swf_url, player.flash_width, player.flash_height, player.flash_options)
	output << "</script>\n";
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
      c.define_tag('audio') { |t| data[:options].player.render("audio_#{paragraph.id}") }
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
