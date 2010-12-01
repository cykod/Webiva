class Webform::PageFeature < ParagraphFeature
  feature :webform_page_form, :default_feature => <<-FEATURE
  <cms:webform>
   <cms:submitted>Thank you <cms:name/></cms:submitted>
   <cms:not_submitted>
    <cms:form>
     <cms:field>
      <div class='item'>
        <cms:error><div class='error'><cms:value/></div></cms:error>
        <div class='label'><cms:label/>:</div>
        <div class='field'><cms:control/></div>
      </div>
     </cms:field>
     <cms:captcha/>
     <cms:submit/>
    </cms:form>
   </cms:not_submitted>
  </cms:webform>
  FEATURE

  def webform_page_form_feature(data)
    webiva_feature(:webform_page_form,data) do |c|
      c.expansion_tag('webform') { |t| data[:result] }

      if data[:result]
        form_opts = {:html => {:multipart => true}}
        c.form_for_tag('webform:form',"results_#{paragraph.id}",form_opts) { |t| data[:result].data_model }
        c.expansion_tag('no_name') { |t| myself.missing_name? }
        c.publication_field_tags('webform:form', data[:result].content_model)
        c.button_tag('webform:form:submit')
        c.captcha_tag('webform:form:captcha') { |t| data[:captcha] if data[:options].captcha }
        c.expansion_tag('webform:submitted') { |t| data[:saved] }
        c.h_tag('webform:submitted:name') { |t| data[:result].name }
      end
    end
  end

  feature :webform_page_display, :default_feature => <<-FEATURE
    <cms:results/>
  FEATURE

  def webform_page_display_feature(data)
    webiva_feature(:webform_page_display,data) do |c|
      c.define_tag('results') do |t|
        t.locals.total_results = data[:options].webform_form ? data[:options].webform_form.total_results : 0

        if t.single?
          t.locals.total_results
        else
          t.expand
        end
      end

      c.value_tag('results:total_results') { |t| t.locals.total_results }

      data[:options].webform_form.result_content_model_fields.each do |row|
        field = row[0]
        result = row[1]

        if field.field_options['options'] && field.field_options['options'].length > 0
          options_tag_helper(c, field, result)
        elsif field.representation == :boolean
          boolean_tag_helper(c, field, result)
        end
      end if data[:options].webform_form

    end
  end

  def options_tag_helper(c, field, result, base='results')
    tally = result.inject(0) { |sum, obj| sum + obj[1] }

    c.define_tag("#{base}:#{field.field}") do |t|
      if t.single?
        "#{field.name}<br/>" + field.module_class.available_options.collect { |option| "#{option[0]}: #{result[option[1]]}" }.join('<br/>')
      else
        t.expand
      end
    end

    c.h_tag("#{base}:#{field.field}:name") { |t| field.name }
    c.loop_tag("#{base}:#{field.field}:option") { field.module_class.available_options }
    c.h_tag("#{base}:#{field.field}:option:name") { |t| t.locals.option[0] }
    c.value_tag("#{base}:#{field.field}:option:total") { |t| result[t.locals.option[1]] }
    c.value_tag("#{base}:#{field.field}:option:percent") { |t| ((result[t.locals.option[1]].to_f/tally.to_f) * 100.0).to_i }    
  end

  def boolean_tag_helper(c, field, result, base='results')
    c.define_tag("#{base}:#{field.field}") do |t|
      if t.single?
        "#{h field.name}: #{result}"
      else
        t.expand
      end
    end

    c.h_tag("#{base}:#{field.field}:label") { |t| field.name }
    c.value_tag("#{base}:#{field.field}:total") { |t| result }
    c.value_tag("#{base}:#{field.field}:percent") { |t| ((result.to_f/t.locals.total_results.to_f) * 100.0).to_i }
  end
end
