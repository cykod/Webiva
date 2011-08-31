
class Editor::SearchFeature < ParagraphFeature #:nodoc:all
  include ActionView::Helpers::FormOptionsHelper

  feature :search_page_search_box, :default_feature => <<-FEATURE
    <cms:search_box>
      Search: <cms:q/> <cms:category/>
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
        <cms:pages/>
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
      c.pagelist_tag('search:results:pages') { |t| data[:pages] }
    end
  end

  def add_search_box_feature(context, data, base='search_box')
    context.define_tag('search_box') do |t|
      t.locals.form = data[:search]
      "<form method='get' action='#{data[:options].search_results_page_url}'>" + t.expand + '</form>'
    end

      context.form_error_tag('search_box:errors')

      context.define_tag('search_box:q') { |t| text_field_tag(:q, t.locals.form.terms, t.attr) }

      context.define_tag('search_box:type') { |t| select_tag(:type, options_for_select(data[:search].content_types_options, t.locals.form.content_type_id), t.attr) }

      context.define_tag('search_box:per_page') do |t|
        options = t.attr['options'] ? t.attr['options'].split(',') : [10, 20, 30, 50]
        opts = t.attr.clone
        opts.delete('options')
        select_tag :per_page, options_for_select(options, t.locals.form.per_page), opts
      end

      context.expansion_tag('search_box:has_categories') { |t| ! data[:search].categories.empty? }
      context.define_tag('search_box:category') { |t| select_tag(:category, options_for_select(data[:search].category_options, t.locals.form.category_id), t.attr) }

      context.define_tag('search_box:published_after') { |t| text_field_tag(:published_after, t.locals.form.published_after, t.attr) }
      context.define_tag('search_box:published_before') { |t| text_field_tag(:published_before, t.locals.form.published_before, t.attr) }
    
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
