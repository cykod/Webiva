# Copyright (C) 2009 Pascal Rettig.

module ParagraphHelper
  def paragraph_options_form_for(name,action=nil,obj=nil,options={},&block)
    obj ||= @options
    if !action
      action = name
      name = name.to_s.humanize + " Options"
    end
    options = options.clone
    options[:html] ||= {}
    options[:html][:id] = "#{action}_form"
    options[:html][:onsubmit] = "cmsEdit.submitParagraphData(this,'#{url_for :action => action}',#{@paragraph.id},#{@paragraph_index}); return false;"

    output = "<h3>#{name.t}</h3>"

    output << form_tag('', options.delete(:html) || {})
    output << cms_fields_for(action.to_sym,obj,options,&block)
    output << "<input type='hidden' name='site_template_id' value='#{h @site_template_id}'/>"
    output << "<hr/>"
    
    if feature_type = @paragraph.feature_type
      features = SiteFeature.single_feature_type_hash(@site_template_id,feature_type,:include_all => true)          
      if features.length > 0
        output << <<-EOF
            <div class='label'>Site Feature: <select name='site_feature_id'>#{options_for_select [["Default Style".t,nil]] + features, @paragraph.site_feature_id }</select></div>
        EOF
      end
    end
    
    output << "</form>"
    output << <<-EOF
      <hr/>
      <a class='cms_ajax_link' href='javascript:void(0);' onclick="$('#{action}_form').onsubmit();">#{"Update &amp; Close".t}</a>
      <a class='cms_ajax_link' href='javascript:void(0);' onclick='cmsEdit.closeBox();'>#{"Cancel".t}</a>
    EOF
    output.html_safe
  end
end

