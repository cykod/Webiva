class <%= module_class %>::<%= renderer_class %>Renderer < ParagraphRenderer

  features '/<%= module_path %>/<%= renderer_path %>_feature'

<%- paragraphs.each do |paragraph| -%>
  paragraph :<%= paragraph %>
<%- end -%>

<%- paragraphs.each do |paragraph| -%>
  def <%= paragraph %>
    @options = paragraph_options :<%= paragraph %>

    # Any instance variables will be sent in the data hash to the 
    # <%= module_path %>_<%= renderer_path %>_<%= paragraph %>_feature automatically
  
    render_paragraph :feature => :<%= module_path %>_<%= renderer_path %>_<%= paragraph %>
  end

<%- end -%>
end
