class SimpleContent::PageFeature < ParagraphFeature

  feature :simple_content_page_structured_view, :default_feature => <<-FEATURE
  <cms:feature>
    Setup up site feature...
  </cms:feature>
  <cms:no_feature>
    Configure simple content model
  </cms:no_feature>
  FEATURE

  def simple_content_page_structured_view_feature(data)
    webiva_feature(:simple_content_page_structured_view,data) do |c|
      c.expansion_tag('feature') { |t| t.locals.entry = data[:options].data_model if data[:options].valid? }

      if data[:options].simple_content_model
        data[:options].simple_content_model.content_model_fields.each do |fld|
          fld.site_feature_value_tags(c, 'feature')
        end
      end
    end
  end

end
