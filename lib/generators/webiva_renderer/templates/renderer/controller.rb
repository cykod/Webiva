class <%= module_class %>::<%= renderer_class %>Controller < ParagraphController

  editor_header '<%= module_name %> Paragraphs'
  
<%- paragraphs.each do |paragraph| -%>
  editor_for :<%= paragraph %>, :name => "<%= paragraph.humanize %>", :feature => :<%= module_path %>_<%= renderer_path %>_<%= paragraph %>
<%- end -%>

<%- paragraphs.each do |paragraph| -%>
  class <%= paragraph.camelcase %>Options < HashModel

  end
<%- end -%>

end
