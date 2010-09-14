class SimpleContent::PageRenderer < ParagraphRenderer

  features '/simple_content/page_feature'

  paragraph :structured_view, :cache => true

  def structured_view
    @options = paragraph_options(:structured_view)

    if ! editor?
      unless @options.valid?
        return render_paragraph :text => 'Reconfigure paragraph'.t if myself.editor?
        return render_paragraph :nothing => true
      end
    end

    render_paragraph :feature => :simple_content_page_structured_view
  end
end
