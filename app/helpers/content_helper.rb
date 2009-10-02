# Copyright (C) 2009 Pascal Rettig.

module ContentHelper
  include ApplicationHelper
  
  def content_field(f,field,options = {})
    
    field_name = options.delete(:field) || field.field
    noun = field.name
    
    field_size = options.delete(:size).to_i
    field_size = 40 if field_size == 0 
    
    required = field.field_options['required'] || false
    
    label = options.delete(:label) || field.name
    
    field_opts = {:size => field_size || 40, :label => label, :required => required, :noun => noun}
    if options[:editor]
      field_opts[:description] = field.description.blank? ? nil : field.description
    end
    
    case field.field_type
    when 'email', 'string', 'integer':
      field_opts[:class] = 'text_field'
      f.text_field field_name, options.merge(field_opts)
    when 'text','html':
      field_opts.delete(:size)
      field_opts[:rows] = 8
      field_opts[:cols] = options[:cols] || field_size || 40
      field_opts[:class] = 'text_area'
      f.text_area field_name, options.merge(field_opts)
    when 'editor':
      field_opts.delete(:size)
      field_opts[:rows] = 15
      field_opts[:cols] = options[:cols] || field_size || 80
      f.editor_area field_name, options.merge(field_opts)
    when 'belongs_to':
      cls = field.field_options['relation_class'].constantize
      field_opts.delete(:size)
      f.select field_name, [['--Select %s--' / field.name, nil ]] + cls.select_options, field_opts, options
    when 'datetime':
      f.datetime_field field_name, options.merge(field_opts)
    when 'date':
      f.date_field field_name, options.merge(field_opts)
    when 'us_state':
      f.select field_name, ContentModel.state_select_options, options.merge(field_opts), :style => 'width:60px;'
    when 'options': 
      field_opts.delete(:size)
      case options[:control].to_s
      when 'radio'
        field_opts[:class] = 'radio_buttons'
        f.radio_buttons field_name, field.content_model.content_model.send(field.field + "_select_options")  , options.merge(field_opts)
      when 'radio_vertical'
        field_opts[:class] = 'radio_buttons'
        field_opts[:separator] = '<br/>'
        f.radio_buttons field_name,field.content_model.content_model.send(field.field + "_select_options")  , options.merge(field_opts)
      else
        f.select field_name, field.content_model.content_model.send(field.field + "_select_options") , options.merge(field_opts)
      end
    when 'multi_select':
        field_opts.delete(:size)
        field_opts[:separator] = "<br/>"
        val =  f.object.send(field_name)
        if !val.is_a?(Array)
           f.object.send("#{field_name}=",val.to_s.split("\n"))
        end
        f.check_boxes field_name,  field.content_model.content_model.send(field.field + "_select_options") , options.merge(field_opts)
    when 'image':
      if options[:editor]
        f.filemanager_image field_name, options.merge(field_opts)
      else
        f.upload_image field_name, options.merge(field_opts)
      end
    when 'document':
        if options[:editor]
          f.filemanager_file field_name, options.merge(field_opts)
        else
          f.upload_document field_name, options.merge(field_opts)
        end
    else
      f.label_field field_name, options
    end
  end
  
  def display_content_field(f,field,options = {}) 
    options = options.clone    
    field_name = options.delete(:field) || field.field
    noun = field.name
    
    
    required = field.field_options['required'] || false
    
    label = options.delete(:label) || field.name
    
    field_opts = options.merge({:label => label, :required => required, :noun => noun})
    
    case field.field_type
    when 'belongs_to':
      relation = f.object.send(field.field_options['relation_name'])
      f.custom_field field.field, 
            :field_opts.merge(:value => relation ? "#{relation.identifier_name}" : '')
    when 'date':
      dt = f.object.send(field.field)
      f.custom_field field.field, field_opts.merge(:value => dt ? dt.localize("%m/%d/%Y".t) : '')
    when 'datetime':
      dt = f.object.send(field.field)
      f.custom_field field.field, field_opts.merge( :value => dt ? dt.localize("%m/%d/%Y %I:%M %p".t) : '')
    #when 'options': 
    #  f.select field.field, field.field_options['options']
    when 'image':
      domain_file = f.object.send(field.field_options['relation_name'])
      if domain_file
        f.custom_field field.field, field_opts.merge( :value => "<a href='#{domain_file.url()}'  target='_blank'><img src='#{domain_file.url(:icon)}' align='absmiddle' />" + h(domain_file.name) + "</a>")
      else
        f.custom_field field.field, field_opts.merge( :value => '[Empty]')
      end
    when 'document':
      domain_file = f.object.send(field.field_options['relation_name'])
      if domain_file
        f.custom_field field.field, field_opts.merge( :value => "<a href='#{domain_file.url()}' target='_blank'><img src='/images/site/document.gif' align='absmiddle' />" + h(domain_file.name) + "</a>")
      else
        f.custom_field field.field, field_opts.merge( :value => '[Empty]')
      end
    when 'text':
      val = f.object.send(field.field)
      f.custom_field field.field, field_opts.merge(:format => 'br',:value => val)
    when 'html':
      val = f.object.send(field.field)
      f.custom_field field.field, field_opts.merge(:value => val)
    when 'multi_select':
      val = f.object.send(field.field)
      val = [] unless val.is_a?(Array)
      val = val.find_all() { |vl| !vl.blank?}
      f.custom_field field.field, field_opts.merge(:value => val.join(", "))
    when 'options'
      f.custom_field "#{field.field}_display", field_opts.merge(:value => (val||[]).join(", "))
    else
      val = f.object.send(field.field)
      f.custom_field field.field, field_opts.merge( :value => val)
    end
  end
  
  def display_content_excerpt(entry,fld)
    display_content_value(entry,fld,:excerpt => true)
  end
   
  def display_content_value(entry,fld,options = {})
    options = options.symbolize_keys
    case fld.field_type
    when 'belongs_to':
      h entry.send(fld.field_options['relation_name']) ? entry.send(fld.field_options['relation_name']).identifier_name : ''
    when 'text':
      if options[:excerpt]
        h truncate(entry.send(fld.field),20)
      else options[:format]
        val = entry.send(fld.field)
        case options[:format]
        when 'simple':
          simple_format(val)
        when 'list':
          "<ul class='#{fld}_list'>" + val.to_s.split("\n").find_all { |elm| !elm.blank?}.map { |elm| "<li>#{h elm.strip}</li>" }.join("\n") + "</ul>"
      	when 'none':
  	      h(val)
  	    when 'html'
  	      val
        else
          h(val).gsub("\n","<br/>")
        end
      end
    when 'html':
      if options[:excerpt]
        content_smart_truncate(strip_tags(entry.send(fld.field)).to_s)
      else
        entry.send(fld.field)
      end 
        
    when 'editor':
      if options[:excerpt]
        content_smart_truncate(strip_tags(entry.send(fld.field)).to_s)
      else
        entry.send(fld.field)
      end

    when 'date':
      dt = entry.send(fld.field) 
      dt ? dt.localize(options[:format] || "%m/%d/%Y".t) : ''
    when 'datetime':
      dt = entry.send(fld.field) 
      dt ? dt.localize(options[:format] || "%m/%d/%Y %I:%M %p".t) : ''
    when 'image':
      domain_file = entry.send(fld.field_options['relation_name'])
      size = options[:size] || 'icon'
      align = options[:align] 
      align = "align='#{align}'" if align
      
      if domain_file
        "<img src='#{domain_file.url(size.to_sym)}' #{align} />"
      else
        ''
      end
    when 'multi_select':
      val = entry.send(fld.field)
      val = [] unless val.is_a?(Array)
      val = val.find_all() { |vl| !vl.blank?}
      h val.join(", ")
    when 'options'
      entry.send("#{fld.field}_display")
      
    when 'document':
      h entry.send(fld.field_options['relation_name']) ? entry.send(fld.field_options['relation_name']).name: ''
    else
      val = entry.send(fld.field)
      if options[:excerpt]
        content_smart_truncate(val)
      elsif options[:format] && options[:format] == 'html'
      else
        h val
      end
    end
  
  end
  
  def content_smart_truncate(val)
      val = val.to_s
      if(val  && val.length > 30 && !val.include?(' '))
        sanitize( truncate(val,30))
      else
        sanitize( truncate(val,60))
      end        
  end
  
  # Helper function that renders a publication table
  def render_publication_table(publication,data,options = {})
    # Figure out what type of publication this is
    pages = data[0]
    data = data[1]
    # See if we have a feature
    if !publication.data['table_class'].to_s.empty?
      table_class = "class='#{publication.data['table_class']}'"
    else
      table_class = ''
    end
    output = ''
    detail_page = options[:detail_page]
    current_page = options[:current_page].to_s
    
    if (publication.data['creation_link'] || []).include?('show')
      output += "<div align='right'><a href='#{detail_page}/'>+ Add Entry</a></div>"
    end
    # Render
      case publication.publication_type
      when 'admin_list','list':
        output += "<table #{table_class}><tr>"
        publication.content_publication_fields.each do |fld|
          output += "<th>#{fld.label}</th>"
        end
        output +="</tr>"
        (data || []).each do |entry|
          output +="<tr>"
	  publication.content_publication_fields.each do |fld|
	    case fld.content_model_field_id
	    when -1:
	     output += "<td><form action='#{detail_page}/#{entry.id}' method='get'><input type='submit' value='#{vh 'Edit'.t}'/></form></td>"
	    when -2:
	     output += "<td><form action='' method='post'><input type='hidden' name='delete' value='#{entry.id}'/> <input type='submit' value='#{vh 'Delete'.t}' onclick='return confirm(\"#{jh 'Are you sure you want to delete this entry?'.t}\");'></form></td>"
	    else 
	     if fld.data[:options].include?('link')
  	       output += "<td><a href='#{detail_page}/#{entry.id}'>#{display_content_excerpt(entry,fld.content_model_field)}</a></td>"
	     else
      	       output += "<td>#{display_content_excerpt(entry,fld.content_model_field)}</td>"
	     end
	    end
	  end
	  output +="</tr>"
        end
        output += "</table>"
        if pages[:pages] > 1
          output += pagination(current_page,pages)
        end
        output
      else
        'Invalid Table'
      end
  end
  
  # Helper function that renders a publication view
  def render_publication_view(publication,data,options = {})
    if publication.publication_type == 'view'
      result = '<table>'
      publication.content_publication_fields.each do |fld|
	if fld.field_type == 'value'
	  result += "<tr><td valign='baseline'>#{fld.label}:</td><td valign='baseline'>#{display_content_value(data,fld.content_model_field)}</td></tr>"
	end
      end
      result += "</table>"
      if !options[:return_page].to_s.strip.blank?
        result +=" <a href='#{options[:return_page]}'>#{'Return'.t}</a><br/>"
      end
      result
    else
      'Invalid Publication View'
    end
  end
  
  # Helper function that renders a entry form
  # Needs a ActionView form object (i.e. from form_for)
  # to display the proper fields
  def render_publication_form(publication,data,frm,options = {})
    # Figure out what type of publication this is
    
    # See if we have a feature
    
    # Render
      case publication.publication_type
      when 'create', 'edit':
        render_publication_edit_form(publication,data,frm,options)
      else
        'Invalid Form'
      end
  end
  
  
  def render_publication_edit_form(publication,data,frm,options={})
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
        result += content_field(frm,fld.content_model_field,:label => fld.label,:size => size, :control => fld.data[:control], :vertical => vertical, :editor => editor)
      elsif fld.field_type == 'value'
        result += display_content_field(frm ,fld.content_model_field,:label => fld.label,:size => size, :control => fld.data[:control], :vertical => vertical, :editor => editor)
      end
    end
    unless options[:no_buttons] 
      if pub_options[:return_button].blank?
        if !pub_options[:submit_button_image_id].blank? && img = DomainFile.find_by_id(pub_options[:submit_button_image_id])
          result += frm.image_submit_tag(img.url)
        else
          result += frm.submit_tag(pub_options[:button_label].blank?  ? 'Create' : pub_options[:button_label])
        end
      else
          result += frm.submit_cancel_tags( (pub_options[:button_label].blank? ? 'Create' : pub_options[:button_label]), pub_options[:return_button], {}, { :onclick => "document.location='#{options[:return_page]}'; return false;" })
      end
    end
    result
  end
  
  def content_publication_filter_options(f,publication)
    fields = ''
    publication.content_publication_fields.each do |fld|
      field = fld.content_model_field
      if (fld.data[:options] || []).include?('filter') 
        label_name = fld.content_model_field.name + " Filter".t
        field_name = "filter_#{fld.id}"
	      case fld.content_model_field.field_type
	      when 'email', 'string', 'integer','text','text':
	        fields += f.text_field(field_name, {:size => 40, :label => label_name})
	        fields += f.check_boxes(field_name.to_s + "_not_empty",[ ['Not Empty','value']], :label => label_name )
	      when 'belongs_to':
	        cls = field.field_options['relation_class'].constantize
	        fields += f.select(field_name, cls.select_options, {:label => label_name})
	      when 'datetime','date':
	        fields += f.select(field_name + "_start", 
	                           ContentPublication.relative_date_start_options, 
	                           :label => (label_name + " Start".t))
	        fields += f.select(field_name + "_end", 
	                           ContentPublication.relative_date_end_options, 
	                           :label => (label_name + " End".t))
	      when 'options': 
                fields += f.check_boxes(field_name, publication.content_model.content_model.send(field.field + "_select_options"), :label => label_name)
        when 'us_state':
               fields += f.check_boxes(field_name, ContentModel.state_select_options, :label => label_name)
	      end      
      end 
    end 
    fields
  end
  
  # Fill any necessary entries with dynamic values or preset values
  # Needs to be a helper as we need access to request/ip/time/etc
  def fill_entry(publication,entry,user = nil,options = {})
    user = myself unless user
    publication.content_publication_fields.each do |fld|
      if fld.field_type == 'dynamic'
        val = nil
        case fld.data[:dynamic].to_s
        when 'email':
          val =user.email
        when 'page_connection':
          val = options[:page_connection]
          if fld.content_model_field.field_type == 'options' # validate input if it's an option
            fnd = fld.content_model_field.field_options['options'].find { |opt| opt=opt.split(";;"); opt[-1].strip == val.to_s }
            val = fnd ? val : ''
          end
        when 'user_id'
          val = user.id
        when 'current'
          val = Time.now
        when 'ip_address':
          val = request.remote_ip
        when 'city':
          begin
            val = MapZipcode.find_by_zip(entry.zipcode).city
          rescue Exception => e
            val =''
          end
        when 'state'
          begin
            val = MapZipcode.find_by_zip(entry.zipcode).state
          rescue Exception => e
            val =''
          end
        when 'user_identifier'
          val = user.identifier_name
        end
        entry.send("#{fld.content_model_field.field}=",val)
      elsif fld.field_type == 'preset'
        entry.send("#{fld.content_model_field.field}=",fld.data[:preset])
      end
    end
  end
  
end
