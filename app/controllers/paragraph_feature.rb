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
  
  def self.dummy_renderer
    ParagraphRenderer.new(UserClass.get_class('domain_user'),ApplicationController.new,PageParagraph.new,SiteNode.new,PageRevision.new)
  end

 def self.document_feature(name)
    rnd = self.dummy_renderer
    feature = self.new(PageParagraph.new,rnd)
    feature.set_documentation(true)
    feature.send(name,{})
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
    
    def define_value_tag(name,field='value',&block)
      define_tag(name) do |tag|
        val = yield(tag)
        if tag.single?
          val
        else
          tag.locals.send("#{field}=",val)
          if tag.attr['equals']
            eql = val.is_a?(Integer) ? tag.attr['equals'].to_i : tar.attr['equals']
            val == eql ? tag.expand : nil
          elsif tag.attr['include']
            inc = val.is_a?(Array) && val.include?(tag.attr['include'])
            inc ? tag.expand : nil
          elsif tag.attr['not_equals']
            eql = val.is_a?(Integer) ? tag.attr['not_equals'].to_i : tar.attr['not_equals']
            val != eql ? tag.expand : nil
          elsif tag.attr['min']
            min = val.is_a?(Integer) ? tag.attr['min'].to_i : tar.attr['min']
            val >= min ? tag.expand : nil
          elsif tag.attr['max']
            max = val.is_a?(Integer) ? tag.attr['max'].to_i : tar.attr['max']
            val <= max ? tag.expand : nil
          else
            if val.is_a?(Array)
              val.length == 0 || val[0].blank? ? nil : tag.expand
            else
              val.blank? ? nil : tag.expand
            end
          end
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
      define_tag name do |tag|
        obj = yield tag if block_given?
        if obj || !block_given?
          opts = options.clone
          opts[:url] ||= ''
          frm_tag =  form_tag(opts.delete(:url), opts.delete(:html) || {}) + opts.delete(:code).to_s
          cms_unstyled_fields_for(arg,obj,opts) do |f|
            tag.locals.form = f
            frm_tag + tag.expand + "</form>"
          end
        else
          nil
        end
      end
    end
    
    def define_fields_for_tag(name,arg,options = {})
      define_tag name do |tag|
        obj = yield tag
        opts = options.clone
        opts[:url] ||= ''
        if obj || !block_given?
          cms_unstyled_fields_for(arg,obj,opts) do |f|
            tag.locals.form = f
            opts.delete(:code).to_s + tag.expand
          end
        else
          nil
        end
      end
    end
        
    
    def define_form_error_tag(name) 
      define_tag name do |tag|
        frm = tag.locals.form
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
        name = options[:name] || tag.attr['name'] || 'commit'
        if  !block_given? || yield(t)
          if(t.attr['type'].to_s == 'image')
            tag('image',
                :class => 'submit_tag submit_image',
                :name => name,
                :value => t.attr['value'] || options[:value] || 'Submit',
                :src => t.expand,
                :align => absmiddle,
                :onclick => onclick )
          else
              tag('input', { :type => 'submit',
                    :class => 'submit_tag',
                    :name => name,
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
      define_tag name do |t|
        if t.locals.form.object.id.blank?
          nil
        else
          <<-TAGS 
            <input type='hidden' name='#{t.locals.form.object_name}_delete' value='0' id='#{t.locals.form.object_name}_delete' />
            <input type='submit' onclick='$("#{t.locals.form.object_name}_delete").value="1"; return true;' value='#{vh t.expand}'/>
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
    
    def define_form_field_tag(name,options={},&block)
      options = options.clone
      
      name_parts = name.split(":")
      pre_tag = name_parts[0..-2].join(":")
      pre_tag += ":" unless pre_tag.blank?
      tag_name = name_parts[-1]
      
      control_type = options.delete(:control) || 'text_field'
      field_name = options.delete(:field) || tag_name
      options[:class] ||= control_type
      
      # Block contains the options for an options control 
      # otherwise it just wraps the output
      options_control = %w(select radio_buttons check_boxes).include?(control_type.to_s)
      field_opts = options.delete(:options) if options_control
      
      define_tag "#{pre_tag}#{tag_name}" do |tag|

        atr = tag.attr.symbolize_keys
        frm = tag.locals.form
        
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
            control_opts = block.call(tag)
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
    
      define_tag "#{pre_tag}#{tag_name}_error" do |tag|
        frm = tag.locals.form
        errs = frm.object.errors.on(field_name)
        if errs.is_a?(Array)
          errs = errs.uniq
          val = errs.collect { |msg| 
            (tag.attr['label'] || field_name.humanize) + " " + msg.t + "<br/>"
          }.join("\n")
        elsif errs
          val = fld.label + " " + errs.t
        end
        
        if tag.single?
          val
        elsif val 
          tag.locals.value = val
          tag.expand
        else 
          nil
        end        
      end
      
      define_tag "#{pre_tag}#{tag_name}_error:value" do |tag|
        tag.locals.value
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
        define_tag(prefix + 'index') { |tag| (tag.attr['modulus'] ?  ((tag.locals.index) % tag.attr['modulus'].to_i)+1 : tag.locals.index+1)}
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
       arr.each_with_index do |value,idx|
          tag.locals.send("#{field}=",value)
          tag.locals.first = value == arr.first
          tag.locals.last =  value == arr.last
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
 
 def webiva_custom_feature(feature_content)
    parser_context = FeatureContext.new(self) { |c| yield c }
    parse_feature(SiteFeature.new(:body_html => feature_content),parser_context)
 end
    
  
 def get_feature(type,options = {})
    if @para.site_feature && @para.site_feature.feature_type == type.to_s
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
        "<div><b>#{'Feature Definition Contains an Error'.t}</b><br/>#{err.to_s.t}</div>"
      rescue Radius::UndefinedTagError => err
        "<div><b>#{'Feature Definition Contains an Undefined tag:'.t}</b>#{err.to_s.t}</div>"
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
    opts = options.merge(:site_node => @renderer.paragraph.page_revision.revision_container_id, 
                         :page_revision => @renderer.paragraph.page_revision.id,
                         :paragraph => @renderer.paragraph.id)
    paragraph_action_url(opts)
  end  
   
end
