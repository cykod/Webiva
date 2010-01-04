class <%= module_class %>::<%= renderer_class %>Feature < ParagraphFeature

<%- paragraphs.each do |paragraph| -%>
  feature :<%= module_path %>_<%= renderer_path %>_<%= paragraph %>, :default_feature => <<-FEATURE
    <%= paragraph.humanize %> Feature Code...
  FEATURE

  def <%= module_path %>_<%= renderer_path %>_<%= paragraph %>_feature(data)
    webiva_feature(:<%= module_path %>_<%= renderer_path %>_<%= paragraph %>,data) do |c|
      # c.define_tag ...
    end
  end

<%- end -%>
end
