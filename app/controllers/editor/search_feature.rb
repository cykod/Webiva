
class Editor::SearchFeature < ParagraphFeature

  feature :search_page_search_box, :default_feature => <<-FEATURE
    <cms:search_box>
      Search: <cms:terms/> <cms:content_type_id/> <cms:per_page/>
      <cms:submit/>
    </cms:search_box>
  FEATURE

  def search_page_search_box_feature(data)
    webiva_custom_feature(:search_page_search_box,data) do |c|
      add_search_box_feature(c, data)
    end
  end

  feature :search_page_search_results, :default_feature => <<-FEATURE
    <cms:search>
      <cms:results>
        <cms:result>
          <div class="search_result">
            <h3><cms:result_link><cms:title/></cms:result_link></h3>
            <cms:excerpt><div class="excerpt"><cms:value/></div></cms:excerpt>
            <cms:preview><div class="preview"><cms:value/></div></cms:preview>
            <cite><cms:display_url/></cite>
          </div>
        </cms:result>
      </cms:results>
      <cms:no_results>
        <div class="search_result">
          No results found.
        </div>
      </cms:no_results>
    </cms:search>
  FEATURE

  def search_page_search_results_feature(data)
    webiva_custom_feature(:search_page_search_results,data) do |c|
      add_search_box_feature(c, data)

      c.expansion_tag('search') { |t| data[:searched] }
      c.value_tag('search:total_results') { |t| data[:total_results] }
      c.loop_tag('search:result') { |t| data[:results] }
        add_result_features(c, data, 'search:result')
    end
  end

  def add_search_box_feature(context, data, base='search_box')
    context.form_for_tag('search_box','search', :url => data[:options].search_results_page_url) { |t| t.locals.search = data[:search] }
      context.form_error_tag('search_box:errors')
      context.field_tag('search_box:terms')
      context.field_tag('search_box:content_type_id', :options => data[:search].content_types_options, :control => 'select')
      context.field_tag('search_box:per_page', :options => [10, 20, 30, 50], :control => 'select')
      context.submit_tag('search_box:submit', :default => 'Submit')
  end

  def add_result_features(context, data, base='result')
    context.h_tag(base + ':title') { |t| t.locals.result[:title] }
    context.h_tag(base + ':subtitle') { |t| t.locals.result[:subtitle] }
    context.value_tag(base + ':excerpt') { |t| t.locals.result[:excerpt] }
    context.value_tag(base + ':preview') { |t| t.locals.result[:preview] }
    context.value_tag(base + ':url') { |t| t.locals.result[:url] }
    context.value_tag(base + ':display_url') { |t| t.locals.result[:url] }
    context.link_tag(base + ':result') { |t| t.locals.result[:url] }
  end
end
