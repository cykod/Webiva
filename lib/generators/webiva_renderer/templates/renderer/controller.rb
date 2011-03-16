class <%= module_class %>::<%= renderer_class %>Controller < ParagraphController

  editor_header '<%= module_name %> Paragraphs'
  
<%- paragraphs.each do |paragraph| -%>
  editor_for :<%= paragraph %>, :name => "<%= paragraph.humanize %>", :feature => :<%= module_path %>_<%= renderer_path %>_<%= paragraph %>
<%- end -%>

<%- paragraphs.each do |paragraph| -%>
  class <%= paragraph.camelcase %>Options < HashModel
    # Paragraph Options
    # attributes :success_page_id => nil

    options_form(
                 # fld(:success_page_id, :page_selector) # <attribute>, <form element>, <options>
                 )
  end

<%- end -%>
end
