
class Editor::ContentFeature < ParagraphFeature #:nodoc:all

  feature :recent_content, :default_feature => <<-FEATURE
  <cms:contents>
    <cms:content>
      <h3><cms:content_link><cms:title/></cms:content_link> <span>on <em><cms:updated_at/></em></span></h3>
      <cms:type/> <cms:category/>
    </cms:content>
  </cms:contents>
  FEATURE

  def recent_content_feature(data)
    webiva_custom_feature(:recent_content,data) do |c|
      c.loop_tag('content') { |t| data[:nodes] }
        self.content_node_tags('content', c, data)
    end
  end

  def content_node_tags(prefix, c, data)
    c.h_tag(prefix + ':title') { |t| t.locals.content.title }
    c.h_tag(prefix + ':author') { |t| t.locals.content.author.name if t.locals.content.author }
    c.h_tag(prefix + ':category') { |t| t.locals.content.content_type.type_description if t.locals.content.content_type }
    c.h_tag(prefix + ':type') { |t| t.locals.content.content_type.content_name if t.locals.content.content_type }
    c.link_tag(prefix + ':content') { |t| t.locals.content.link }
    c.datetime_tag(prefix + ':updated_at') { |t| t.locals.content.updated_at }
    c.datetime_tag(prefix + ':created_at') { |t| t.locals.content.created_at }
  end
end
