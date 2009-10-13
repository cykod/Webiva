class <%= module_class %>::<%= renderer_class %>Renderer < ParagraphRenderer

  features '/<%= module_path %>/<%= renderer_path %>_feature'

<%- paragraphs.each do |paragraph| -%>
  paragraph :<%= paragraph %>
<%- end -%>

<%- paragraphs.each do |paragraph| -%>
  def <%= paragraph %>
  
    data = {}
    
    render_paragraph :text => <%= module_path %>_<%= renderer_path %>_<%= paragraph %>_feature(data)
  end
<%- end -%>


end
