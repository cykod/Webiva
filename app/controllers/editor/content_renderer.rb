
class Editor::ContentRenderer < ParagraphRenderer #:nodoc:all

  features '/editor/content_feature'

  paragraph :recent_content

  def recent_content
    @options = paragraph_options(:recent_content)

    conditions = @options.content_type_ids.length > 0 ? {  :content_type_id => @options.content_type_ids } : {}
    conditions[:published] = true
    @nodes = ContentNode.find(:all,:conditions => conditions, :limit => @options.count, :order => @options.order )

    render_paragraph :feature => :recent_content
  end

end
