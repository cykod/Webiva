# Copyright (C) 2009 Pascal Rettig.


class Content::CorePublication::CreatePublication < Content::PublicationType #:nodoc:all


  class CreateOptions < HashModel
    attributes :button_label => nil, :submit_button_image_id => nil, :return_button => nil, :field_size => nil,:form_class => nil,:form_display => 'horizontal', :allow_entry_creation => nil, :fields => []
    
    integer_options :submit_button_image_id, :field_size
  end
  
  options_class CreateOptions
  options_partial '/content/core_publication/form_publication_options'
  
  field_types :input_field, :preset_value, :dynamic_value
  
  # No Field options
  
  register_triggers :view, :create

  feature_name 'form'
  
  
 def default_feature
    output = "<cms:submitted><cms:success_text/></cms:submitted>\n"
    output += "<cms:form>\n"
    output += "<table class='styled_table'>\n\n"
    self.content_publication_fields.each do |fld|
      if fld.field_type == 'input' 
        if self.options.form_display == 'vertical'
          output += "<tr class='vertical'>\n"
          output += "  <td class='label_vertical' colspan='2' >" + fld.label + (fld.required? ? "*" : '') + "</td>\n"
          output += "</tr>\n"
          output += "<cms:#{fld.content_model_field.feature_tag_name}_error>\n"
          output += "<tr><td colspan='2' class='error'><cms:value/></td></tr>\n"
          output += "</cms:#{fld.content_model_field.feature_tag_name}_error>\n"
          output += "<tr>\n"
          output += "  <td nowrap='1' class='vertical_data' colspan='2'><cms:#{fld.content_model_field.feature_tag_name}/></td>\n"
          output += "</tr>\n\n"
        else
          output += "<cms:#{fld.content_model_field.feature_tag_name}_error>\n"
          output += "<tr><td></td><td class='error'><cms:value/></td></tr>\n"
          output += "</cms:#{fld.content_model_field.feature_tag_name}_error>\n"
          output += "<tr>\n"
          output += "  <td nowrap='1' class='label'>" + fld.label + (fld.required? ? "*" : '') + "</td>\n"
          output += "  <td nowrap='1' class='data'><cms:#{fld.content_model_field.feature_tag_name}/></td>\n"
          output += "</tr>\n"
        end
      end
    end 
    output += "<tr>\n"
    output += "  <td colspan='2' align='right'><cms:create_butt/></td>\n"
    output += "</tr>\n"
    output += "</table>\n"
    output += '</cms:form>'
    
    output
  end  
  
  def render_form(f,options={})
    result = ''
    editor = options[:editor]
    pub_options = publication.data || {}
    size = pub_options[:field_size] || nil;
    if options.has_key?(:vertical)
      vertical = options[:vertical]
    else
      vertical = pub_options[:form_display] == 'vertical' ? true : nil
    end
    publication.content_publication_fields.each do |fld|
      if fld.field_type == 'input'
        result <<  fld.form_field(f, :vertical => vertical, :editor => editor).to_s
      elsif fld.field_type == 'value'
        result << f.custom_field(fld.content_model_field.feature_tag_name, :label => fld.label, :value => fld.content_display(f.object,:preview))
      end
    end
    unless options[:no_buttons] 
      if pub_options[:return_button].blank?
        if !pub_options[:submit_button_image_id].blank? && img = DomainFile.find_by_id(pub_options[:submit_button_image_id])
          result << f.image_submit_tag(img.url)
        else
          result << f.submit_tag(pub_options[:button_label].blank?  ? 'Create' : pub_options[:button_label])
        end
      else
          result << f.submit_cancel_tags( (pub_options[:button_label].blank? ? 'Create' : pub_options[:button_label]), pub_options[:return_button], {}, { :onclick => "document.location='#{options[:return_page]}'; return false;" })
      end
    end
    result    
  end
  
 
  def preview_data
    @publication.content_model.content_model.new
  end
      
  
end



