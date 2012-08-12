class LookingFor::PageFeature < ParagraphFeature

  feature :looking_for_page_view, :default_feature => <<-FEATURE
  <div id="next" class="opt">
    <h4>Looking For</h4>
    <h5><cms:title /></h5>
    <ul>
    <cms:locations>
        <cms:location>
          <li>
            <cms:document_present>
              <cms:document_link><cms:action_text /></cms:document_link>
            </cms:document_present>
            <cms:page_present>
              <cms:page_link><cms:action_text /></cms:page_link>
            </cms:page_present>
            <span><cms:description_text /></span>
          </li>
        </cms:location>
    </cms:locations>
    </ul>
    <cms:no_locations>Please select at least one feature.</cms:no_locations>
  </div>

  FEATURE

  def looking_for_page_view_feature(data)
    webiva_feature(:looking_for_page_view, data) do |c|
      c.loop_tag('location') { |t| data[:locations] }
      c.expansion_tag('page_present') { |t| ! t.locals.location[:page].blank? }
      c.expansion_tag('document_present') { |t| ! t.locals.location[:document].blank? }
      c.link_tag('page') { |t| SiteNode.find_page(t.locals.location[:page]).link }
      c.link_tag('document') { |t| t.locals.location[:document] }
      c.attribute_tags('location',%w(action_text description_text page)) { |t| t.locals.location }
      c.value_tag('title') { |t| data[:options].title }
    end
  end

end
