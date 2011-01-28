class NextSteps::PageFeature < ParagraphFeature

  feature :next_steps_page_view, :default_feature => <<-FEATURE
  <div id="next" class="opt">
    <h4>Next Steps</h4>
    <h5><cms:title /></h5>
    <ul>
    <cms:steps>
        <cms:step>
          <li>
            <cms:document_present>
              <cms:document_link><cms:action_text /></cms:document_link>
            </cms:document_present>
            <cms:page_present>
              <cms:page_link><cms:action_text /></cms:page_link>
            </cms:page_present>
            <span><cms:description_text /></span>
          </li>
        </cms:step>
    </cms:steps>
    </ul>
    <cms:no_steps>Please select at least one feature.</cms:no_steps>
  </div>

  FEATURE

  def next_steps_page_view_feature(data)
    webiva_feature(:next_steps_page_view, data) do |c|
      c.loop_tag('step') { |t| data[:steps] }
      c.expansion_tag('page_present') { |t| ! t.locals.step[:page].blank? }
      c.expansion_tag('document_present') { |t| ! t.locals.step[:document].blank? }
      c.link_tag('page') { |t| SiteNode.find_page(t.locals.step[:page]).link }
      c.link_tag('document') { |t| t.locals.step[:document] }
      c.attribute_tags('step',%w(action_text description_text page)) { |t| t.locals.step }
      c.value_tag('title') { |t| data[:options].title }
    end
  end

end
