# Copyright (C) 2009 Pascal Rettig.

require 'radius'

class ParagraphFeature

  # Include some helpers needed for
  # rendering pages
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormHelper
  include ERB::Util
  include EscapeHelper
  include ActionView::Helpers::FormTagHelper


  def initialize(paragraph,renderer)
    @para = paragraph
    @renderer = renderer
  end
  
  def method_missing(method,*args)
    if method.to_s =~ /feature$/
      raise 'Undefined feature:' + method.to_s
    else
      if args.length > 0
        @renderer.send(method,*args)
      else
        @renderer.send(method)
      end
    end
  end
  
  def self.dummy_renderer(controller=nil)
    ParagraphRenderer.new(UserClass.get_class('domain_user'),controller || ApplicationController.new,PageParagraph.new,SiteNode.new,PageRevision.new)
  end

  def self.document_feature(name,data={},controller=nil,publication=nil)
    rnd = self.dummy_renderer(controller)
    feature = self.new(PageParagraph.new,rnd)
    feature.set_documentation(true)
    feature.send(name,data)
  end
  
  def self.feature(type,opts = {})
    features = self.available_features
    features << type
    
    sing = class << self; self; end
    sing.send :define_method, :available_features do 
      return features
    end 
    
    opts[:default_feature] ||= ''
    sing.send :define_method, "get_default_feature_#{type.to_s}" do
      opts[:default_feature]
    end
    opts[:default_data] ||= {}
    sing.send :define_method, "get_default_data_#{type.to_s}" do
      opts[:default_data]
    end
  end
  
  
  
  class FeatureContext < Radius::Context 
    include ActionView::Helpers::TagHelper
    include EscapeMethods
    include ActionView::Helpers::FormTagHelper
    include ActionView::Helpers::FormHelper
    include StyledFormBuilderGenerator::FormFor
    include ActionView::Helpers::FormOptionsHelper
    include PageHelper
    include EscapeHelper
    
    
    def url_for(opts)
      ''
    end
    
    def initialize(renderer=nil)
      @renderer = renderer
      super()
    end
    
  def method_missing(method,*args)
    if args.length > 0
      @renderer.send(method,*args)
    else
      @renderer.send(method)
    end
  end
    
  def define_attribute_tags(name,tag_names,&block)
    tag_names.each do |tag_name|
      define_attribute_tag_helper("#{name}:#{tag_name}",tag_name,block)
    end
  end
        
        def define_attribute_tag_helper(name,tag_name,block)
          define_value_tag(name) do |t|
              h(block.call(t).send(tag_name))
          end
        end
    
    # Wrap a value tag in an escape
    def define_h_tag(name,field='value',options={},&block)
      case options[:format]
      when :simple
        define_value_tag(name,field,&Proc.new { |t| val = block.call(t); val ? simple_format(h(val)) : nil })
      else
        define_value_tag(name,field,&Proc.new { |t| val = block.call(t); val ? h(val) : nil })
      end
    end

    def value_tag_helper(t,field,val)
      t.locals.send("#{field}=",val)
      if t.attr['equals']
        eql = val.is_a?(Integer) ? t.attr['equals'].to_i : t.attr['equals']
        val == eql ? t.expand : nil
      elsif t.attr['contains']
        contains = t.attr['contains'].to_s.split(",").map { |elm| elm.strip.blank? ? nil : elm.strip }.compact
        contains.include?(val) ? t.expand : nil
      elsif t.attr['include']
        inc = val.is_a?(Array) && val.include?(t.attr['include'])
        inc ? t.expand : nil
      elsif t.attr['not_equals']
        eql = val.is_a?(Integer) ? t.attr['not_equals'].to_i : tar.attr['not_equals']
        val != eql ? t.expand : nil
      elsif t.attr['min']
        min = val.is_a?(Integer) ? t.attr['min'].to_i : tar.attr['min']
        val >= min ? t.expand : nil
      elsif t.attr['max']
        max = val.is_a?(Integer) ? t.attr['max'].to_i : tar.attr['max']
        val <= max ? t.expand : nil
      elsif t.attr['link']
        
      else
        if val.is_a?(Array)
          val.length == 0 || val[0].blank? ? nil : t.expand
        else
          val.blank? ? nil : t.expand
        end
      end
    end
    
    def define_value_tag(name,field='value',&block)
      define_tag(name) do |tag|
        val = yield(tag)
        if tag.single?
          val
        else
          value_tag_helper(tag,field,val)
        end
      end
      
      name_parts = name.split(":")
      name_parts[-1] = "no_" + name_parts[-1]
      
      define_tag(name_parts.join(":")) do |tag|
        val = block.call(tag)
        val.blank? ? tag.expand : nil
      end
      define_tag(name + ":#{field}") do |tag|
        tag.locals.send(field)
      end
    end
    
    def define_loop_tag(name,plural=nil)
      name_parts = name.split(":")
      name_base = name_parts[-1]
      plural = name_base.pluralize unless plural
      name_parts[-1] = plural
      
      expansion_tag = name_parts.join(":")
      define_tag(name) { |t| each_local_value(yield(t),t,name_base) }
      define_expansion_tag(expansion_tag) { |t| arr = yield(t); arr && arr.length > 0 }
    end
    
    def define_expansion_tag(name) 
      define_tag(name) do |tag|
        yield(tag) ? tag.expand : nil
      end
      name_parts = name.split(":")
      tg_name = name_parts[-1]
      name_parts[-1] = "no_" + tg_name
      
      define_tag(name_parts.join(":")) do |tag|
        yield(tag) ? nil : tag.expand
      end
      name_parts[-1] = "not_" + tg_name
      define_tag(name_parts.join(":")) do |tag|
        yield(tag) ? nil : tag.expand
      end

    end
    
    def define_date_tag(name,default_format = '%m/%d/%Y',&block)
      define_value_tag(name) do |tag|
        val = yield(tag)
        if !val.is_a?(Time)
          begin 
            val = Time.parse(val)
          rescue Exception => e
            #
          end
        end
        val.localize(tag.attr['format'] || default_format) if val
      end
    end

    def reset_output
      @output_buffer = ""
    end
    
    def concat(txt,binding=nil)
      @output_buffer += txt
    end
    
    attr_reader :output_buffer

    
    def define_end_user_table_tag(tag_name,field,options = {},&block) 
      options.symbolize_keys!
      define_tag(tag_name) do |t|
        
        opts = options.clone.merge(t.attr.symbolize_keys.slice(:empty,:style,:width))
        opts[:empty] ||= "No Entries"
        
        t.locals.tbl = yield t
        reset_output
        end_user_table_for(t.locals.tbl,opts) do |row|
          t.locals.send("#{field}=",row)
          concat(t.expand)
        end
        output_buffer
      end
      define_tag("#{tag_name}:row") do |t|  
        "<tr #{t.locals.tbl.highlight_row(t.locals.send(field))}>" + t.expand + "</tr>"
      end      
      
      define_tag("#{tag_name}:row:checkbox") do |t|
        t.locals.tbl.entry_checkbox(t.locals.send(field))
      end
    end
    
    def define_user_tags(tag_name)
    
      define_expansion_tag(tag_name) { |t| yield t }
      define_expansion_tag(tag_name + ":logged_in") { |t| usr = yield t; !usr.id.blank? }
      define_value_tag(tag_name + ":name") { |t| usr = yield t; usr.name if usr }
      define_value_tag(tag_name + ":first_name") { |t| usr = yield t; usr.first_name if usr }
      define_value_tag(tag_name + ":last_name") { |t| usr = yield t; usr.last_name if usr }
      define_value_tag(tag_name + ":profile") { |t| usr = yield t; usr.profile_id if usr }
      define_expansion_tag(tag_name + ":myself") { |t| usr = yield t; usr == myself if usr }
    
    end

    def define_user_details_tags(name_base,options={})
      local=options[:local]
      if !local
        name_parts = name_base.split(":")
        local = name_parts[-1]
      end
      expansion_tag("#{name_base}:myself") { |t| t.locals.send(local) == myself }
      expansion_tag("#{name_base}:male") { |t| t.locals.send(local).gender == 'm' }
      expansion_tag("#{name_base}:female") { |t| t.locals.send(local).gender == 'f' }
      define_value_tag("#{name_base}:user_id") { |t| t.locals.send(local).id }
      define_value_tag("#{name_base}:first_name") { |t| t.locals.send(local).first_name }
      define_value_tag("#{name_base}:last_name") { |t| t.locals.send(local).last_name }
      define_value_tag("#{name_base}:salutation") { |t| t.locals.send(local).salutation }
      define_value_tag("#{name_base}:name") { |t| t.locals.send(local).name }
      define_value_tag("#{name_base}:email") { |t| t.locals.send(local).email }
      define_image_tag("#{name_base}:img") { |t| t.locals.send(local).image }
      define_image_tag("#{name_base}:second_img") { |t| t.locals.send(local).second_image }
      define_image_tag("#{name_base}:fallback_img") { |t| t.locals.send(local).second_image || t.locals.send(local).image }

      expansion_tag("#{name_base}:address") { |t| t.locals.address = t.locals.send(local).address }
      define_user_address_tags("#{name_base}:address")
      
      expansion_tag("#{name_base}:work_address") { |t| t.locals.work_address = t.locals.send(local).work_address }
      define_user_address_tags("#{name_base}:work_address")

    end

    def define_user_address_tags(name_base,options={})
       local=options[:local]
      if !local
        name_parts = name_base.split(":")
        local = name_parts[-1]
      end

      define_value_tag("#{name_base}:display") { |t| t.locals.send(local).display(t.attr['separator'] || "<br/>") }
      
      %w(address address_2 company phone fax city state zip country).each do |fld|
        define_h_tag("#{name_base}:#{fld}") { |t| t.locals.send(local).send(fld) }
      end
      
    end

    def image_tag_helper(tag,img,tag_opts)
      # Handle rollovers
      if img.is_a?(Array)
        rollover = img[1]
        object_id = img[2]
        img = img[0]
      end
      
      attr = tag.attr.clone
      if img 
        icon_size = attr.delete('size') || tag_opts[:size] || nil
        size = icon_size #%w(icon thumb preview small original).include?(icon_size) ?  icon_size : nil
        size = nil if size == 'original'
        img_size = img.image_size(size)
        shadow = attr.delete('shadow')
        align = attr.delete('align') 
        field = attr.delete('field')
        
        case field
        when 'width':
            img_tag = img_size[0].to_s
        when 'height':
            img_tag = img_size[1].to_s
        when 'dimensions':
            img_tag =  "width='#{img_size[0].to_s}' height='#{img_size[1].to_s}'"
        when 'src':
            img_tag = img.url(size)
        else
          if shadow
            shadow_align = align
            border_amt = (attr.delete('border') || 1).to_i
            if(align == 'left')
              border = "0 #{border_amt}px #{border_amt}px 0px"
            elsif(align == 'right')
              border = "0 0 #{border_amt}px #{border_amt}px"
            else
              border = 0
            end
          else
            attr['align'] = align
            border_amt = (attr.delete('border') || 1).to_i
            attr['style'] = (!attr['style'].blank?) ? attr['style'] + ';' : ''
            if(align == 'left')
              attr['style'] += "margin: 0 #{border_amt}px #{border_amt}px 0px;"
            elsif(align == 'right')
              attr['style'] += "margin: 0 0 #{border_amt}px #{border_amt}px"
            end
          end
          
          img_url = img.url(size)
          img_opts =  { :src => img_url,:width => img_size[0],:height => img_size[1] }
          attr.symbolize_keys!
          if attr[:width] || attr[:height]
            img_opts.delete(:width)
            img_opts.delete(:height)
          end
          unless img_size[0] && img_size[0].to_i > 1 && img_size[1].to_i > 1
            img_opts.delete(:width)
            img_opts.delete(:height)
          end
          tag_opts = attr.merge(img_opts)
          if rollover
            tag_opts[:onmouseover] = "WebivaMenu.swapImage(this,'#{jvh img_url}','#{jvh  rollover.url(size)}','#{object_id}'); " + tag_opts[:onmouseover].to_s
            tag_opts[:onmouseout] = "WebivaMenu.restoreImage(this,'#{object_id}'); " + tag_opts[:onmouseout].to_s
            preload = "<script>WebivaMenu.preloadImage('#{jvh rollover.url(size)}');</script>"
          end
          img_tag =  tag('img',tag_opts) + preload.to_s
          img_tag = "<div style='float:#{shadow_align}; margin:#{border}; #{attr['style']}'><div style='width:#{img_size[0] + 12}px; float:#{shadow_align};' class='cms_gallery_shadow'><div><p>" + img_tag + "</p></div></div></div>" if shadow
        end
        if tag.single?
          img_tag
        else
          tag.locals.value = img_tag
          tag.expand
        end            
      else
        nil
      end

    end
    
      def define_image_tag(tag_name,local_obj=nil,attribute=nil,tag_opts={})
        define_tag tag_name + ":value" do |tag|
          tag.locals.value
        end
        
        obj_value = Proc.new() do |tag|
          if local_obj
            obj = tag.locals.send(local_obj)
            if(obj)
              if block_given?
                if attribute
                  img = yield obj.send(attribute), tag
                else
                  img = yield obj,tag
                end
              elsif attribute
                img = obj.send(attribute)
              else
                img = obj
              end
            end
          else
            img = yield tag
          end
        end
        tag_parts = tag_name.split(":")
        tag_parts[-1] = "no_" + tag_parts[-1]
        define_tag tag_parts.join(":") do |tag|
          img = obj_value.call(tag)
          img ? nil : tag.expand
        end
        
        define_tag tag_name do |tag|
          img = obj_value.call(tag)
          image_tag_helper(tag,img,tag_opts)
        end
    end
    
      def define_form_tag(frm,name)
      define_tag name do |tag|
        expand = block_given? ? yield : true
        if expand
          tag.locals.form = frm
          "<form action='' method='post'>" + tag.expand + "</form>"
        else
          nil
        end
      end
    end
    
      def define_form_for_tag(name,arg,options = {})
        frm_obj = options[:local] || 'form'
        define_tag name do |tag|
          obj = yield tag if block_given?
          if obj || !block_given?
            opts = options.clone
            if obj.is_a?(Hash)
              arg_obj = obj.delete(:object)
              opts = opts.merge(obj)
              obj = arg_obj
            end
            opts[:url] ||= ''
            frm_tag =  form_tag(opts.delete(:url), opts.delete(:html) || {}) + opts.delete(:code).to_s
            cms_unstyled_fields_for(arg,obj,opts) do |f|
              tag.locals.send("#{frm_obj}=",f)
              frm_tag + tag.expand + "</form>"
            end
          else
            nil
          end
        end
      end
      
      def define_fields_for_tag(name,arg,options = {})
        frm_obj = options.delete(:local) || 'form'
        define_tag name do |tag|
          obj = yield tag
          opts = options.clone
          opts[:url] ||= ''
          if obj || !block_given?
            cms_unstyled_fields_for(arg,obj,opts) do |f|
              tag.locals.send("#{frm_obj}=",f)
              opts.delete(:code).to_s + tag.expand
            end
          else
            nil
          end
        end
      end

      def define_publication_form_error_tag(name,publication,options={})
        frm_obj = options.delete(:local) || 'form'
        define_value_tag name do |t|
          output = []
          frm = t.locals.send(frm_obj)
          publication.content_publication_fields.each do |fld|
            err = frm.output_error_message(fld.label,fld.content_model_field.field)
            output << err if err
          end
          output.join()
        end
      end
    
      def define_form_error_tag(name,options={})
        frm_obj = options.delete(:local) || 'form'
        define_tag name do |tag|
          frm = tag.locals.send(frm_obj)
          if frm && frm.object && frm.object.errors && frm.object.errors.length > 0
            if tag.single?
              frm.object.errors.full_messages.join(tag.attr['separator'] || "<br/>")
            else
              tag.locals.value = frm.object.errors.full_messages.join(tag.attr['separator'] || "<br/>")
              tag.expand           
            end          
          else
            nil
        end
      end
      
      define_tag "#{name}:value" do |tag|
        tag.locals.value            
      end
    end
    
    def define_button_tag(name,options={})
      onclick = options.delete(:onclick)
      define_tag name do |t|
        name = options[:name] || t.attr['name'] || 'commit'
        if  !block_given? || yield(t)
          if(t.attr['type'].to_s == 'image')
            tag('input',
                :type => 'image',
                :class => 'submit_tag submit_image',
                :name => name,
                :value => t.attr['value'] || options[:value] || 'Submit',
                :src => t.expand,
                :id => t.attr['id'] || options[:id],
                :align => :absmiddle,
                :onclick => onclick )
          else
              tag('input', { :type => 'submit',
                    :class => 'submit_tag',
                    :name => name,
                    :id => t.attr['id'] || options[:id],
                    :value => t.single? ?
                    (t.attr['value'] || options[:value] || 'Submit') : t.expand,
                    :onclick => onclick })
          end
        else
          nil
        end
      end
    end
    
    def define_delete_button_tag(name,options={})
      frm_obj = options[:local] || 'form'
      define_tag name do |t|
        if t.locals.send(frm_obj).object.id.blank?
          nil
        else
          <<-TAGS 
            <input type='hidden' name='#{t.locals.send(frm_obj).object_name}_delete' value='0' id='#{t.locals.send(frm_obj).object_name}_delete' />
            <input type='submit' onclick='$("#{t.locals.send(frm_obj).object_name}_delete").value="1"; return true;' value='#{vh t.expand}'/>
          TAGS
        end
      end
    end
    
  def define_submit_tag(tag_name,options = {:default => 'Submit'.t })

    self.define_tag tag_name do |tag|
      output =''
      if tag.single?
        txt = tag.attr['value'] || options[:default]
        output ="<input type='submit' name='button' value='#{vh txt}'/>"
      else
                        
        if !block_given? || yield
          if tag.attr['type'] == 'image'
            output = "<input type='image' src='#{vh tag.expand}' align='absmiddle'/>"
          else
            output = "<input type='submit' class='submit_tag' name='button' value=\"#{tag.expand}\"/>"
          end
        else
          output = nil
        end
      end
      if(options.has_key?(:form))
        if !options[:form]
          nil
        else
          "<form action='#{options[:form]}' method='#{options[:method]||'get'}'>" + output + "</form>"
        end
      else
        output
      end
    end
  end
    
    
    def define_link_tag(name,options={})
      name_base = name[-1..-1] == ":" ? name : name + "_"
    
      define_value_tag(name_base + "url") do |tg| 
        url = yield tg  
        if url.is_a?(Hash)
          url[:href]
        else
          url
        end
      end
      
      define_tag(name_base + "link") do |tg|
        attr = tg.attr.clone
        selected = attr.delete('selected_class')
        url = yield(tg)
        if url.blank?
          nil
        elsif url.is_a?(Hash)
          url_selected = url.delete(:selected)
          url[:class] = selected if selected && url_selected
          tag('a',attr.merge(options).merge(url),true) + tg.expand + "</a>" 
        else
          tag('a',attr.merge(options).merge({ :href => url }),true) + tg.expand + "</a>" 
        end
      end
      define_value_tag(name_base + "href") do |tg| 
        url = yield tg  
        if url.is_a?(Hash)
          url.to_a.map { |elm| "#{elm[0]}='#{vh elm[1]}'" }.join(" ")
        else
          "href='#{url}'"
        end
      end
    end
    
    include SimpleCaptcha::ViewHelpers 
    
    def define_captcha_tag(name,options={}) 
      define_tag(name) do |t|
        options[:field_value] ||= set_simple_captcha_data(options[:code_type])
        simple_captcha_options = 
          {:image => simple_captcha_image(options),
           :label => options[:label] || "(type the code from the image)",
           :field => simple_captcha_field(options)}
        render_to_string :partial => '/simple_captcha/simple_captcha_feature', :locals => {:simple_captcha_options  => simple_captcha_options } 
      end
    end
    
    def define_field_tag(name,options={},&block)
      define_form_field_tag(name,options,&block)    
    end

    def form_field_tag_helper(t,frm,control_type,field_name,options={},&block)
      options=options.clone
      atr = t.attr.symbolize_keys
      # Block contains the options for an options control 
      # otherwise it just wraps the output
      options_control = %w(select radio_buttons check_boxes).include?(control_type.to_s)
      field_opts = options.delete(:options) if options_control
            
      
      if control_type == 'select'
        options[:id] ||= "#{frm.object_name}_#{field_name}"
      end
      
      empty_click = atr.delete('prefill')
      if empty_click
        atr['onfocus'] = "if(this.value=='#{jvh empty_click}') this.value=''";
        atr['onblur'] = "if(this.value=='') this.value='#{jvh empty_click}'";
        frm.object.send("#{field_name}=",empty_click) if frm.object.send(field_name).blank?
      end

      if options_control
        if opt_names = atr.delete(:options)
          
          names = opt_names.split(',').collect { |elm| elm.blank? ? nil : elm.strip }.compact
          idx = -1
          control_opts =  field_opts.map do |elm| 
            idx+=1
            [ names[idx] || elm[0], elm[1] ]
          end
        elsif field_opts
          control_opts = field_opts
        else
          control_opts = block.call(t)
        end
        
        if control_type.to_s == 'select'
          output = frm.select_tag("#{frm.object_name}[#{field_name}]",options_for_select(control_opts,frm.object.send(field_name)),options.merge(atr))
        else

          output = frm.send(control_type,field_name,control_opts,options.merge(atr))
        end
      else
        output = frm.send(control_type,field_name,options.merge(atr))
      end
      
      # Block contains the options for an options control 
      # otherwise it just wraps the output
      if block && (!options_control || field_opts)
        block.call(tag,output)
      else
        output
      end
    end
    

    def form_field_error_tag_helper(t,frm,field_name)
      errs = frm.object.errors.on(field_name)
      if errs.is_a?(Array)
        errs = errs.uniq
        val = errs.collect { |msg| 
          (t.attr['label'] || field_name.humanize) + " " + msg.t + "<br/>"
        }.join("\n")
      elsif errs
        val =(t.attr['label'] || field_name.humanize) + " " + errs.t
      end
      
      val
    end
    
    def define_form_field_tag(name,options={},&block)
      options = options.clone
      
      name_parts = name.split(":")
      pre_tag = name_parts[0..-2].join(":")
      pre_tag += ":" unless pre_tag.blank?
      tag_name = name_parts[-1]
      
      
      control_type = options.delete(:control) || 'text_field'
      field_name = options.delete(:field) || tag_name
      options[:class] ||= control_type
      frm_obj = options[:local] || :form
      
     
      define_tag "#{pre_tag}#{tag_name}" do |t|
        form_field_tag_helper(t,t.locals.send(frm_obj),control_type,field_name,options,&block)
      end
    
      define_value_tag "#{pre_tag}#{tag_name}_error" do |t|
        form_field_error_tag_helper(t,t.locals.send(frm_obj),field_name)
      end
    end

    def has_many_field_helper(level,t,value,idx)
      output = ''
     
      if value.is_a?(Hash)
        t.locals.has_many_grouping=value[:name]
        t.locals.has_many_entry=nil
        output << t.expand

        output << has_many_field_helper(level,t,value[:items],idx)
        
      elsif value.is_a?(Array)
        if value[0].is_a?(Hash)
          value.each_with_index do |itm,idx2|
            t.locals.first = idx2 == 0
            t.locals.last =  itm == value.last
            t.locals.index = idx2+1
            t.locals.has_many_level = level
            output << has_many_field_helper(level+1,t,itm,idx2)
          end
        else
          t.locals.has_many_grouping = nil
          t.locals.has_many_entry = value
          output << t.expand
        end
      end
      output
    end

    def define_publication_filter_fields_tags(prefix,arg,publication,options={})

      if block_given?
        define_expansion_tag("#{prefix}_search") { |t| yield(t) }
      else
        define_expansion_tag("#{prefix}_search") { |t| false }
      end

      
      define_button_tag("#{prefix}:submit",:value => 'Search')
      define_button_tag("#{prefix}:clear",:value => 'Clear',:name => "clear_#{arg}")
      publication.content_publication_fields.each do |fld|
        if !fld.options.filter.blank? && fld.options.filter_options.include?('expose')
          fld.filter_variables.each do |var|
            define_value_tag("#{prefix}:#{var}_value") do |t|
              obj = t.locals.send(arg).object
              obj.send(var)
            end
          end
          fld.filter_names.each do |variable|
          
            define_tag("#{prefix}:#{fld.content_model_field.feature_tag_name}_#{variable}") do |t|
              fld.filter_options(t.locals.send(arg),variable,t.attr)
            end
          end
        end
      end
    end


    # Can only be used in webiva_custom_feature
    def define_publication_field_tags(prefix,publication,options = {})
      c = self

      frm_obj = options.delete(:local) || 'form'
      pub_options = publication.options.to_hash
      size = pub_options[:field_size] || nil;

      publication.content_publication_fields.each do |fld|
        if fld.content_model_field.data_field?
          tag_name = fld.content_model_field.feature_tag_name

          if fld.field_type=='input'
            c.define_tag "#{prefix}:#{tag_name}" do |t|
              opts = { :label => fld.label, :size => size }.merge(fld.data)
              opts[:size] = t.attr['size'] if t.attr['size']
              opts = opts.merge(t.attr)
              opts.symbolize_keys!
              fld.form_field(t.locals.send(frm_obj),opts)
            end

            c.value_tag "#{prefix}:#{tag_name}_value" do |t|
              fld.content_value(t.locals.send(frm_obj).object)
            end
            
            c.value_tag "#{prefix}:#{tag_name}_display" do |t|
              fld.content_display(t.locals.send(frm_obj).object,:full,t.attr)
            end
            
            
            c.value_tag "#{prefix}:#{tag_name}_error" do |t|
              t.locals.send(frm_obj).output_error_message(fld.label,fld.content_model_field.field)
            end
          elsif fld.field_type == 'value'
            fld.content_model_field.site_feature_value_tags(c,prefix,:full,:local => frm_obj  )
          end
        end
      end

      if publication.form?
        
        
        c.define_tag("#{prefix}:has_many_field") do |t|
          frm = t.locals.send(frm_obj)
          available_fields = publication.content_publication_fields.map(&:content_model_field).map { |fld| [ fld.feature_tag_name, fld.id, fld ]}

          fields = t.attr['fields'].split(",").map { |fld| fld.strip.blank? ? nil : fld.strip }.compact

          active_fields = available_fields.select { |fld| fields.include?(fld[0]) }.map { |fld| fld[2] } 
          t.locals.has_many_fields = active_fields
          t.locals.has_many_values = t.locals.has_many_fields.map do  |fld|
            frm.object.send("#{fld.field_options['relation_singular']}_ids")
          end

          # TODO: Yeah, not so hot - needs to be extract to core_field somehow
          if active_fields[0] && cls = active_fields[0].relation_class
            cm =  active_fields[0].content_model_relation

            if t.attr['filter_by'] && filter_field = cm.content_model_fields.detect { |fld| fld.field == t.attr['filter_by'] }
              conditions = { filter_field.field => t.attr['filter'] }
            else
              conditions = nil
            end

            if t.attr['order'] && order_field = cm.content_model_fields.detect { |fld| fld.field == t.attr['order'] }
              order_by = "`#{order_field.field}`"
            else
              order_by = nil
            end
            arr = cls.find(:all,:order => order_by,:conditions => conditions)
            if t.attr['group'] && group_field = cm.content_model_fields.detect { |fld| fld.field == t.attr['group'] }

              if t.attr['group_2nd'] && group_2nd_field =  cm.content_model_fields.detect { |fld| fld.field == t.attr['group_2nd'] }
                available_options =  {}
                arr.group_by { |elm| group_field.content_display(elm) }.each do |key,arr2|
                  arr2.group_by { |elm|  group_2nd_field.content_display(elm) }.each do |key2,arr3|
                    available_options[key] ||= {}
                    available_options[key][key2] = arr3.map { |elm| [ elm.identifier_name, elm.id ] }
                  end
                end
                arr = available_options.to_a.map do |elm|
                  [ elm[0],
                    elm[1].to_a.sort { |a,b| a[0].to_s.downcase <=> b[0].to_s.downcase }.map { |elm2| { :name => elm2[0], :items => elm2[1] } }
                  ]
                end.sort { |a,b| a[0].to_s.downcase <=> b[0].to_s.downcase }.map { |elm| { :name => elm[0], :items => elm[1] } }
              else
                available_options =  {}
                arr.group_by { |elm| group_field.content_display(elm) }.each do |key,arr|
                  
                  available_options[key] = arr.map { |elm| [ elm.identifier_name, elm.id ] }
                end
                arr = available_options.to_a.sort { |a,b| a[0].to_s.downcase <=> b[0].to_s.downcase }.map { |elm| { :name => elm[0], :items => elm[1] } }
              end
            else
              arr.map! { |elm| [ elm.identifier_name, elm.id ] }
            end
            output = ''
            output << has_many_field_helper(1,t,arr,0)
          end
          output
        end

        c.value_tag("#{prefix}:has_many_field:grouping") { |t| t.locals.has_many_grouping }
        c.define_tag("#{prefix}:has_many_field:entries") do |t|
          pre = t.attr['pre'] || ''
          post = t.attr['post'] || ''
          prefix = t.attr['prefix']
          align = t.attr['align'] || 'center'
          if !t.locals.has_many_entry
            nil
          else 
            frm = t.locals.send(frm_obj)

            field_names = t.locals.has_many_fields.map { |fld|  "#{fld.field_options['relation_singular']}_ids" }
            output = ''
            values = t.locals.has_many_values

            t.locals.has_many_entry.each do |ent|
              output <<  pre + (prefix ?  "<tr><td class='has_many_label'>#{ent[0]}</td>" : "<tr>")
              t.locals.has_many_fields.each_with_index do |fld,idx|
                output << "<td align='#{align}' class='has_many_item'>" +
                  check_box_tag("#{frm.object_name}[#{field_names[idx]}][]",
                                ent[1],
                                values[idx].include?(ent[1]),
                                :id => "#{frm.object_name}_#{field_names[idx]}_#{ent[1]}") + "</td>"
              end
              output <<( prefix ? "</tr>" :  "<td class='value_label'>#{ent[0]}</td></tr>") + post
            end
            output
          end
        end

        c.value_tag("#{prefix}:has_many_field:level") { |t| t.locals.has_many_level } 

        
        c.loop_tag("#{prefix}:field") do |t|
          fields = publication.content_publication_fields.select { |fld| fld.field_type == 'input' && fld.content_model_field.data_field? }
          if t.attr['except']
            except_fields = t.attr['except'].split(",").map { |elm| elm.blank? ? nil : elm.strip }.compact
            fields = fields.select { |elm| !except_fields.include?(elm.content_model_field.feature_tag_name) }
          end
          if t.attr['fields']
            only_fields = t.attr['fields'].split(",").map { |elm| elm.blank? ? nil : elm.strip }.compact
            fields = fields.select { |elm| only_fields.include?(elm.content_model_field.feature_tag_name) }
          end
          fields
        end

        c.value_tag("#{prefix}:field:label") do |t|
          t.locals.field.label
        end
        c.value_tag("#{prefix}:field:control") do |t|
          opts = { :label => t.locals.field.label, :size => size }.merge(t.locals.field.data)
          opts[:size] = t.attr['size'] if t.attr['size']
          t.locals.field.form_field(t.locals.send(frm_obj),opts.merge(t.attr))
        end
        
        c.value_tag("#{prefix}:field:error") do |t|
          c.form_field_error_tag_helper(t,t.locals.send(frm_obj),t.locals.field.content_model_field.field)
        end
      end

    end

    def define_results_tags(tag_base,options ={ },&block)
      
      define_pagelist_tag("#{tag_base}:pages",options,&block)

      self.value_tag("#{tag_base}:total_results") do |tag|
        page_data = yield(tag)
        page_data[:total]
      end

      self.value_tag("#{tag_base}:first_result") do |tag|
        page_data = yield(tag)
        page_data[:first]
      end

      self.value_tag("#{tag_base}:last_result") do |tag|
        page_data = yield(tag)
        page_data[:last]
      end
      
    end
    
    def define_pagelist_tag(tag_name,options = {}) 
      

      self.define_tag tag_name do |tag|
        page_data = yield(tag)
        if page_data
          page = page_data[:page]
          path = page_data[:path] || ''
          pages = page_data[:pages] || 1

          field = (path.to_s.include?("?") ? '&' : '?') + (options[:field] || 'page')

          display_pages = options[:pages_to_display] || 2
          
          last_page = tag.attr['last'] || "&lt; &lt;"
          next_page = tag.attr['next'] || "&gt; &gt;"
          
          result = ''
          
          if pages > 1
            
            # Show back button
            if page > 1
              result += "<a href='#{path}#{field}=#{page-1}'>#{last_page}</a> &nbsp;&nbsp;"
            end
            # Find out the first page to show
            start_page = (page - display_pages) > 1 ? (page - display_pages) : 1
            end_page = (start_page + (display_pages*2))
            if end_page > pages
              start_page -= end_page - pages - 1
              start_page = 1 if start_page < 1 
              
              end_page = pages
            end
            
            if start_page == 2
              result += " <a href='#{path}#{field}=1'> 1 </a> "
            elsif start_page > 2
              result += " <a href='#{path}#{field}=1'> 1 </a> .. "
            end
            
            (start_page..end_page).each do |pg|
              if pg == page
                result += " <b> #{pg} </b> "
              else
                result += " <a href='#{path}#{field}=#{pg}'> #{pg} </a> "
              end
            end
            
            if end_page == pages - 1
              result += " <a href='#{path}#{field}=#{pages}'> #{pages} </a> "
            elsif end_page < pages - 1
              result += " .. <a href='#{path}#{field}=#{pages}'> #{pages} </a> "
            
            end
            
            # Next Button
            if page < pages
              result += " &nbsp;&nbsp;<a href='#{path}#{field}=#{page+1}'>#{next_page}</a> "
            end
          end
          
          result        
        else
          nil
        end
        
      end      
    end
    
    
    def define_pages_tag(tag_name,path,page,pages,options = {})
      page ||= 1
      # Display the page tags
      
      # get the field to use default to page (e.g. ?page )
      # but check if there are already get args or we need a different var
      field = (path.to_s.include?("?") ? '&' : '?') + (options[:field] || 'page')
      self.define_tag tag_name do |tag|
        display_pages = options[:pages_to_display] || 2
        
        last_page = tag.attr['last'] || "&lt; &lt;"
        next_page = tag.attr['next'] || "&gt; &gt;"
        
        result = ''
        
        if pages > 1
          
          # Show back button
          if page > 1
            result += "<a href='#{path}#{field}=#{page-1}'>#{last_page}</a> &nbsp;&nbsp;"
          end
          # Find out the first page to show
          start_page = (page - display_pages) > 1 ? (page - display_pages) : 1
          end_page = (start_page + (display_pages*2))
          if end_page > pages
            start_page -= end_page - pages - 1
            start_page = 1 if start_page < 1 
            
            end_page = pages
          end
          
          if start_page == 2
            result += " <a href='#{path}#{field}=1'> 1 </a> "
          elsif start_page > 2
            result += " <a href='#{path}#{field}=1'> 1 </a> .. "
          end
          
          (start_page..end_page).each do |pg|
            if pg == page
              result += " <b> #{pg} </b> "
            else
              result += " <a href='#{path}#{field}=#{pg}'> #{pg} </a> "
            end
          end
          
          if end_page == pages - 1
            result += " <a href='#{path}#{field}=#{pages}'> #{pages} </a> "
          elsif end_page < pages - 1
            result += " .. <a href='#{path}#{field}=#{pages}'> #{pages} </a> "
          
          end
          
          # Next Button
          if page < pages
            result += " &nbsp;&nbsp;<a href='#{path}#{field}=#{page+1}'>#{next_page}</a> "
          end
        end
        
        result
      end
    end
    
    def define_position_tags(prefix=nil)
        prefix += ':' if prefix
        prefix = prefix.to_s
        define_tag(prefix + 'index') { |tag| (tag.attr['modulus'] ?  ((tag.locals.index) % tag.attr['modulus'].to_i)+1 : tag.locals.index)}
        define_tag(prefix + 'at') { |tag| tag.attr['index'].to_i == tag.locals.index ? tag.expand : nil }
        define_tag(prefix + 'not_at') { |tag| tag.attr['index'].to_i != tag.locals.index ? tag.expand : nil }
        define_tag(prefix + 'first') { |tag| tag.locals.first ? tag.expand : '' }
        define_tag(prefix + 'last') { |tag| tag.locals.last ? tag.expand : '' }
        define_tag(prefix + 'odd') { |tag| tag.locals.index.odd? ? tag.expand : '' }
        define_tag(prefix + 'even') { |tag| tag.locals.index.even? ? tag.expand : '' }
        define_tag(prefix + 'not_first') { |tag| !tag.locals.first ? tag.expand : '' }
        define_tag(prefix + 'not_last') { |tag| !tag.locals.last ? tag.expand : '' }
        define_tag(prefix + 'middle') { |tag| ( !tag.locals.first && !tag.locals.last ) ? tag.expand : '' }
        define_tag(prefix + 'not_middle') { |tag| (tag.locals.first || tag.locals.last)  ? tag.expand : '' }
        define_tag(prefix + 'multiple') { |tag| ( (tag.locals.index + (tag.attr['offset'] || 1).to_i ) % (tag.attr['value'] || 2).to_i ) == 0 ? tag.expand : '' }
  
    end    
    
    def each_local_value(arr,tag,field = 'value')
      output = ''
      return nil unless arr.is_a?(Array)
      last = arr.length-1
      arr.each_with_index do |value,idx|
        tag.locals.send("#{field}=",value)
        tag.locals.first = idx == 0
        tag.locals.last =  idx == last
        tag.locals.index =  idx+1
        if block_given?
          data = yield value, tag
          output += data.to_s
        else
          output += tag.expand
        end
      end
      output
    end
    
    def define_post_button_tag(tag_name,options = {})
      button_value = options[:button] || 'Submit'
      method = options[:method] || 'post'
      define_tag tag_name do |tag|
        onsubmit = tag.attr['confirm'] ? "onsubmit='return confirm(\"#{jvh tag.attr['confirm']}\");'" : ''
        cls = tag.attr['class'] || 'post_button'
        url = yield tag
        
        if url.blank? 
          nil
        elsif tag.attr['icon'] || (tag.attr['type'] == 'image')
            img_src = (tag.single? ? tag.attr['icon'] : tag.expand)
            "<form class='post_button_form' action='#{vh url}' #{onsubmit} method='#{method}'><input class='#{cls}' type='image' value='submit' src='#{vh img_src}'/></form>"
        else
          button_value = (tag.attr['value'] || (tag.single? ? button_value : tag.expand))
          "<form class='post_button_form' action='#{vh url}'  #{onsubmit}  method='#{method}'><input class='#{cls}' type='submit' value='#{qvh(button_value)}'/></form>"
        end      
      end
    end
    
    def define_login_block(tag_name,login_error)
      define_expansion_tag(tag_name) do |tag|
        user = yield
        user.id ? false : true
      end
      
      define_tag(tag_name + ":form") do |tag|
        "<form action='' method='post'>"  + tag.expand + "</form>"
      end
      
      define_tag(tag_name + ":form:email") do |tag|
        "<input type='text' size='#{tag.attr['size'] || 40}' name='login[email]' value=''/>"
      end
      define_tag(tag_name + ":form:password") do |tag|
        "<input type='password' size='#{tag.attr['size'] || 40}' name='login[password]' value=''/>"
      end
      define_tag(tag_name + ":error") do |tag|
        login_error ? tag.expand : nil
      end
      
      define_button_tag(tag_name + ":button")
    end 
    
    # get versions of all the define_... methods without the define
    skip_methods = %w(define_form_tag define_tag)
    instance_methods.each do |method_name|
      if !skip_methods.include?(method_name) && method_name =~ /define\_(.*)/
        alias_method $1.to_sym, method_name.to_sym
      end
    end
  end  
  
  class FeatureDocumenter
    attr_reader :method_list 
    
    def initialize(renderer)
      @method_list = []
      yield self
    end
    
    def define_loop_tag(name,plural=nil)
      name_parts = name.split(":")
      name_base = name_parts[-1]
      plural = name_base.pluralize unless plural
      name_parts[-1] = plural
      
      expansion_tag = name_parts.join(":")
      define_iteration_tag(name)
      define_expansion_tag(expansion_tag)
    end
    
    def define_link_tag(name,options={})
      name_base = name[-1..-1] == ":" ? name : name + "_"
    
      define_value_tag(name_base + "url")
      define_block_tag(name_base + "link")
      define_value_tag(name_base + "href")
    end

    def define_user_details_tags(name_base,options={})
      expansion_tag("#{name_base}:myself")
      expansion_tag("#{name_base}:male")
      expansion_tag("#{name_base}:female")
      define_value_tag("#{name_base}:user_id")
      define_value_tag("#{name_base}:first_name")
      define_value_tag("#{name_base}:last_name") 
      define_value_tag("#{name_base}:name")
      define_value_tag("#{name_base}:email")
      define_image_tag("#{name_base}:img") 
      define_image_tag("#{name_base}:second_img") 
      define_image_tag("#{name_base}:fallback_img")

      expansion_tag("#{name_base}:address") 
      define_user_address_tags("#{name_base}:address")
      
      expansion_tag("#{name_base}:work_address")
      define_user_address_tags("#{name_base}:work_address")

    end

    def define_publication_filter_fields_tags(prefix,arg,publication,options={})

      define_form_for_tag(prefix)
      define_expansion_tag("#{prefix}_search")
      
      define_button_tag("#{prefix}:search",:value => 'Search')
      define_button_tag("#{prefix}:clear",:value => 'Clear',:name => "clear_#{arg}")      

      define_field_fields_tag("#{prefix}:fields")
      publication.content_publication_fields.each do |fld|
        if !fld.options.filter.blank? && fld.options.filter_options.include?('expose')

          fld.filter_variables.each do |var|
            define_value_tag("#{prefix}:#{var}_value")
          end
          fld.filter_names.each do |variable|
            define_tag("#{prefix}:#{fld.content_model_field.feature_tag_name}_#{variable}")
          end

        end
      end
    end
    
    def define_user_address_tags(name_base,options={})
      define_value_tag("#{name_base}:display")
      
      %w(address address_2 company phone fax city state zip country).each do |fld|
        define_h_tag("#{name_base}:#{fld}")
      end
      
    end

    def define_h_tag(tg,field='value',options={})
      @method_list << [ "Escaped value tag",tg ]
    end


    def define_publication_field_tags(prefix,publication,options={})
      c = self
      local = options.delete(:local) || 'entry'
      
      publication.content_publication_fields.each do |fld|
        if fld.content_model_field.data_field?
          tag_name = fld.content_model_field.feature_tag_name

          if fld.field_type=='input'
            define_form_field_tag "#{prefix}:#{tag_name}" 
            value_tag "#{prefix}:#{tag_name}_value"
            value_tag "#{prefix}:#{tag_name}_display"
            define_form_field_error_tag "#{prefix}:#{tag_name}_error"
          elsif fld.field_type == 'value'
            fld.content_model_field.site_feature_value_tags(c,prefix,:full,:local => local)
          end
        end
      end

      if publication.form?
        define_form_fields_loop_tag("#{prefix}:field")
        define_value_tag("#{prefix}:field:label")
        define_value_tag("#{prefix}:field:control")
        define_value_tag("#{prefix}:field:error")
      end
    end
    
    
    def method_missing(method,*args)
      method = method.to_s
      if method == 'define_tag'
        @method_list << [ 'tag', args[0] ]
      elsif method.to_s =~ /^define_((.*)_tag)$/
        @method_list << [ $1, args[0] ]
      elsif method.to_s =~  /^((.*)_tag)$/
        @method_list << [ $1, args[0] ]
      else
        nil
      end
    end

    
    
     # get versions of all the define_... methods without the define
    skip_methods = %w(define_form_tag define_tag define_form_tag)
    instance_methods.each do |method_name|
      if !skip_methods.include?(method_name) && method_name =~ /define\_(.*)/
        alias_method $1.to_sym, method_name.to_sym
      end
    end    
  end
  
  def self.available_features
    []
  end
  
  def documentation
    @display_documentation ? true : false
  end
  
  def set_documentation(val)
   @display_documentation = val
  end

  # Run a feature where the tags need to be re-parsed each time
  # dummy file
  def webiva_custom_feature(feature_name,data={},&block)
    webiva_feature(feature_name,data,&block)
  end

  # Run a feature that can be cached 
  def webiva_feature(feature_name,data={})
  if !self.documentation
     parser_context = FeatureContext.new(self) do |c| 
      c.define_position_tags  
      yield c
      
      # Get each of the handler option models
      # See if this feature has an extensions
      get_handler_info(:site_feature,feature_name).each do |handler|
          handler[:class].send("#{feature_name}_feature".to_sym,c,data)
      end      
      
     end 
     parse_feature(get_feature(feature_name),parser_context)
  else
    documenter = FeatureDocumenter.new(self) do |c|
      yield c
    end
    documenter.method_list.sort { |a,b| a[1] <=> b[1] }
  end
 end
 
#  def webiva_custom_feature(feature_content)
#    parser_context = FeatureContext.new(self) { |c| yield c }
#    parse_feature(SiteFeature.new(:body_html => feature_content),parser_context)
# end
    
  
 def get_feature(type,options = {})
    if @para.site_feature && (@para.site_feature.feature_type == :any || @para.site_feature.feature_type == type.to_s)
      feat = @para.site_feature
      feat
    else
      if @para.content_publication
        SiteFeature.new(:body_html => @para.content_publication.default_feature, :options => {})
      else
        if options[:class_name]
          SiteFeature.new(:body_html => options[:class_name].constantize.send("get_default_feature_#{type}"), :options=> { :default => true})
        else
          SiteFeature.new(:body_html => self.class.send("get_default_feature_#{type}"), :options=> { :default => true})
        end
      end
    end
  end
  
  
  def parse_feature(feature,context)
      options = feature.options || {}
        
      SiteTemplate.add_standard_parsing!(context,:values => options[:values],
                                                 :language => @language, 
                                                 :localize_values => options[:localize_values],
                                                 :localize => options[:localize],
                                                 :default_feature => options[:default] )
      feature_parser = Radius::Parser.new(context, :tag_prefix => 'cms')
      begin
        feature_parser.parse(feature.body_html || feature.body)
      rescue  Radius::MissingEndTagError => err
        if myself.editor?
          "<div><b>#{'Feature Definition Contains an Error'.t}</b><br/>#{err.to_s.t}</div>"
        else
          ""
        end
      rescue Radius::UndefinedTagError => err
        if myself.editor?
          "<div><b>#{'Feature Definition Contains an Undefined tag:'.t}</b>#{err.to_s.t}</div>"
        else
          ""
        end
      end
  end
  
  
  def variable_replace(txt,vars = {})
    txt.gsub(/\%\%(\w+)\%\%/) do |mtch|
      var_name =$1.downcase.to_sym
      vars[var_name] ? vars[var_name] : ''
    end
  end
  
  def module_options(md)
    cls = "#{md.to_s.camelcase}::AdminController".constantize
    cls.module_options
  end
  
   def ajax_url(options={})
     if @renderer.paragraph &&  @renderer.paragraph.page_revision
       opts = options.merge(:site_node => @renderer.paragraph.page_revision.revision_container_id, 
                            :page_revision => @renderer.paragraph.page_revision.id,
                            :paragraph => @renderer.paragraph.id)
       paragraph_action_url(opts)
     end
  end  
   
end
