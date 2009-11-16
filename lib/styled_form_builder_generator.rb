# Copyright (C) 2009 Pascal Rettig.

module StyledFormBuilderGenerator
        

  module FormFor

  end

  module Generator
    module ClassMethods
      def generate_styled_fields(options_func,
                                      field_helpers,
                                      &proc)
        field_helpers.each do |fld|
          if self.method_defined?(fld)
            alias_method "#{fld}_original", fld
          end
          
          define_method fld do |field,*args|
            output = lambda do |opts|
              if opts.is_a?(Hash)
                if args.last.is_a?(Hash)
                  args[-1] = args.last.merge(opts)
                else
                  args << opts
                end
              end
              super(field,*args)
            end
            options = args.last.is_a?(Hash) ? args.last : {}
            
            @options = self.send(options_func,fld,field,output,options)
            self.instance_eval(&proc)
          end
          
        end
      end
      
      # generates functions named class_name_for  and remote_class_name_for in the ApplicationHelper
      # (e.g. calling from TabledForm results in tabled_form_for and remote_tabled_form_for 
      # pre is the markup that appears after the form tag but before the fields
      # post is the makrup that appears after the fields but before the end form tag
      # available options:
      #   :display_only => true  - does not generate form tags, used for display forms
      #   :name => 'function_name' - creates a function called function_name_for instead 
      #   :no_remote => true - does not generate a remote_ type function
      def generate_form_for(pre = '',post = '',options = {})
          class_name = self.to_s
          display_only = options[:display]  || false
          name = options[:name] || class_name.underscore 
          
          names = [ [ name, 'form_tag(options.delete(:url) || {}, options.delete(:html) || {})'] ]
          names << [ 'remote_' + name, 'form_remote_tag(options)' ]  unless display_only || options[:no_remote]
          names.each do |nm|
            src = <<-END_SRC 
              def #{nm[0]}_for(object_name,*args,&proc)
                raise ArgumentError, "Missing block" unless block_given?
                options = args.last.is_a?(Hash) ? args.pop : {}
                #{"concat(" + nm[1] + ")" unless display_only}
                concat('#{pre}')
                fields_for(object_name, *(args << options.merge(:builder => #{class_name})), &proc)
                concat('#{post.gsub("'","\\'")}')
                #{"concat('</form>')" unless display_only}
              end
            END_SRC
            StyledFormBuilderGenerator::FormFor.class_eval src, __FILE__, __LINE__
            self.class_eval <<-SRC, __FILE__, __LINE__
              module FormFor
                #{src}
              end
            SRC
          end
      end
      
      def generate_fields_for(pre='',post='',options = {})
		    class_name = self.to_s
		    display_only = options[:display]  || false
		    name = options[:name] || class_name.underscore
		    pre_cmd = pre.blank? ? '' : "concat(\"#{pre.gsub(/[\'\"\#]/, '\\\1')}\")"
		    post_cmd = post.blank? ? '' : "concat(\"#{post.gsub(/[\'\"\#]/, '\\\1')}\")"
		    src = <<-END_SRC 
			    def #{name}_for(object_name,*args,&proc)
				    raise ArgumentError, "Missing block" unless block_given?
				    options = args.last.is_a?(Hash) ? args.pop : {}
            #{pre_cmd}
				    fields_for(object_name, *(args << options.merge(:builder => #{class_name})), &proc)
				    #{post_cmd}
			    end
		    END_SRC
		    StyledFormBuilderGenerator::FormFor.class_eval src, __FILE__, __LINE__   
        self.class_eval <<-SRC,  __FILE__, __LINE__
              module FormFor
                #{src}
              end
        SRC
      end
    end
    
    def self.included(mod)
      mod.class_eval do
        extend ClassMethods
      end 
    end
  end
  
  
  
end


module EnhancedFormElements
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::AssetTagHelper
 
  
    class TranslatedCountries
      include Singleton
      
      def initialize
        @countries = {}
      end 
      
      def get(lang)
        @countries[lang]
      end
      
      def set(lang,arr)
        @countries[lang] = arr
      end
    end
    
     COUNTRIES = ["Afghanistan", "Aland Islands", "Albania", "Algeria", "American Samoa", "Andorra", "Angola",
          "Anguilla", "Antarctica", "Antigua And Barbuda", "Argentina", "Armenia", "Aruba", "Australia", "Austria",
          "Azerbaijan", "Bahamas", "Bahrain", "Bangladesh", "Barbados", "Belarus", "Belgium", "Belize", "Benin",
          "Bermuda", "Bhutan", "Bolivia", "Bosnia and Herzegowina", "Botswana", "Bouvet Island", "Brazil",
          "British Indian Ocean Territory", "Brunei Darussalam", "Bulgaria", "Burkina Faso", "Burundi", "Cambodia",
          "Cameroon", "Canada", "Cape Verde", "Cayman Islands", "Central African Republic", "Chad", "Chile", "China",
          "Christmas Island", "Cocos (Keeling) Islands", "Colombia", "Comoros", "Congo",
          "Congo, the Democratic Republic of the", "Cook Islands", "Costa Rica", "Cote d'Ivoire", "Croatia", "Cuba",
          "Cyprus", "Czech Republic", "Denmark", "Djibouti", "Dominica", "Dominican Republic", "Ecuador", "Egypt",
          "El Salvador", "Equatorial Guinea", "Eritrea", "Estonia", "Ethiopia", "Falkland Islands (Malvinas)",
          "Faroe Islands", "Fiji", "Finland", "France", "French Guiana", "French Polynesia",
          "French Southern Territories", "Gabon", "Gambia", "Georgia", "Germany", "Ghana", "Gibraltar", "Greece", "Greenland", "Grenada", "Guadeloupe", "Guam", "Guatemala", "Guernsey", "Guinea",
          "Guinea-Bissau", "Guyana", "Haiti", "Heard and McDonald Islands", "Holy See (Vatican City State)",
          "Honduras", "Hong Kong", "Hungary", "Iceland", "India", "Indonesia", "Iran, Islamic Republic of", "Iraq",
          "Ireland", "Isle of Man", "Israel", "Italy", "Jamaica", "Japan", "Jersey", "Jordan", "Kazakhstan", "Kenya",
          "Kiribati", "Korea, Democratic People's Republic of", "Korea, Republic of", "Kuwait", "Kyrgyzstan",
          "Lao People's Democratic Republic", "Latvia", "Lebanon", "Lesotho", "Liberia", "Libyan Arab Jamahiriya",
          "Liechtenstein", "Lithuania", "Luxembourg", "Macao", "Macedonia, The Former Yugoslav Republic Of",
          "Madagascar", "Malawi", "Malaysia", "Maldives", "Mali", "Malta", "Marshall Islands", "Martinique",
          "Mauritania", "Mauritius", "Mayotte", "Mexico", "Micronesia, Federated States of", "Moldova, Republic of",
          "Monaco", "Mongolia", "Montenegro", "Montserrat", "Morocco", "Mozambique", "Myanmar", "Namibia", "Nauru",
          "Nepal", "Netherlands", "Netherlands Antilles", "New Caledonia", "New Zealand", "Nicaragua", "Niger",
          "Nigeria", "Niue", "Norfolk Island", "Northern Mariana Islands", "Norway", "Oman", "Pakistan", "Palau",
          "Palestinian Territory, Occupied", "Panama", "Papua New Guinea", "Paraguay", "Peru", "Philippines",
          "Pitcairn", "Poland", "Portugal", "Puerto Rico", "Qatar", "Reunion", "Romania", "Russian Federation",
          "Rwanda", "Saint Barthelemy", "Saint Helena", "Saint Kitts and Nevis", "Saint Lucia",
          "Saint Pierre and Miquelon", "Saint Vincent and the Grenadines", "Samoa", "San Marino",
          "Sao Tome and Principe", "Saudi Arabia", "Senegal", "Serbia", "Seychelles", "Sierra Leone", "Singapore",
          "Slovakia", "Slovenia", "Solomon Islands", "Somalia", "South Africa",
          "South Georgia and the South Sandwich Islands", "Spain", "Sri Lanka", "Sudan", "Suriname",
          "Svalbard and Jan Mayen", "Swaziland", "Sweden", "Switzerland", "Syrian Arab Republic",
          "Taiwan, Province of China", "Tajikistan", "Tanzania, United Republic of", "Thailand", "Timor-Leste",
          "Togo", "Tokelau", "Tonga", "Trinidad and Tobago", "Tunisia", "Turkey", "Turkmenistan",
          "Turks and Caicos Islands", "Tuvalu", "Uganda", "Ukraine", "United Arab Emirates", "United Kingdom",
          "United States", "United States Minor Outlying Islands", "Uruguay", "Uzbekistan", "Vanuatu", "Venezuela",
          "Viet Nam", "Virgin Islands, British", "Virgin Islands, U.S.", "Wallis and Futuna", "Western Sahara",
          "Yemen", "Zambia", "Zimbabwe"] unless const_defined?("COUNTRIES")


    def translated_countries_for_select(priority_countries = nil)
      
      countries = COUNTRIES
      country_options = []
      if priority_countries
        translated_priority_countries = priority_countries.collect { |c| [ c.t, c ] }
        country_options += translated_priority_countries
        country_options += [ [ '-------------------', '' ] ]
      else
        country_options = []
      end

      tc = TranslatedCountries.instance
      countries_translated = tc.get(Locale.language)
      countries_translated = countries.collect { |c| [ c.t, c ] } unless countries_translated

      if priority_countries
        country_options += countries_translated.find_all { |country| !priority_countries.include?(country[1]) }
      else
        country_options += countries_translated
      end
      
      tc.set(Locale.language,countries_translated)
 
      return country_options
    end
    
    def submit_tag(name,options = {}) 
      options[:class] ||= 'submit_button'
      @template.submit_tag(emit_label(name), options)
    end
    
    def image_submit_tag(src,options = {}) 
      options[:class] ||= 'image_submit_button'
      @template.image_submit_tag(src, options)
    end
    
    
    def header(name,options = {})
      emit_label(name)
    end 
    
    def spacer()
      '<br/>'
    end
    
    def label_field(field,options={})
      val = @object.send(field) || ''
      if options[:format] == 'simple'
        simple_format val
      elsif options[:format] = 'br'
        h(val).gsub("\n","<br/>")
      else
        h val
      end
    end  
    
    def custom_field(field,options={},&block)
      if options[:value]
        options[:value] || ''
      else
        yield
      end    
    end
    
    def label_option_field(field,tag_values,options={})
      val = @object.send(field)
      tag_values.each do |fld|
      	if val.to_s == fld[1].to_s
      		return fld[0]
      	end
      end
      return options[:default] || ''
    end

    def grouped_select(field,choices,options ={}, html_options = {})
      obj_val = @object.send(field) if @object
      opts = @template.grouped_options_for_select(choices,obj_val)

      name = "#{@object_name}[#{field}]#"
      select_tag(name,opts,html_options)
    end

    def multiple_selects(field,choices,options={},html_options={})
      labels = options[:labels].to_s.split(",").map { |elm| elm.to_s.strip }
      number = (options.delete(:number)||1).to_i
      number = 1 if number < 1
      number = 10 if number > 10
      separator = options.delete(:separator)||"<br/>"
      obj_val = @object.send(field) if @object
      obj_val = [obj_val] unless obj_val.is_a?(Array)
      obj_val = obj_val.map(&:to_i) if options.delete(:integer)
      name = "#{@object_name}[#{field}][]"
      (1..number).map do |idx|
        opts = @template.options_for_select(choices,obj_val[idx-1])
        labels[idx-1].to_s + select_tag(name,opts,html_options)
      end.join(separator)
    end

    def multiple_grouped_selects(field,choices,options={},html_options={})
      labels = options[:labels].to_s.split(",").map { |elm| elm.to_s.strip }
      number = (options.delete(:number)||1).to_i
      number = 1 if number < 1
      number = 10 if number > 10
      separator = options.delete(:separator)||"<br/>"
      obj_val = @object.send(field) if @object
      obj_val = [obj_val] unless obj_val.is_a?(Array)
      obj_val = obj_val.map(&:to_i) if options.delete(:integer)
      name = "#{@object_name}[#{field}][]"
      (1..number).map do |idx|
        opts = @template.grouped_options_for_select(choices,obj_val[idx-1])
        labels[idx-1].to_s + select_tag(name,opts,html_options)
      end.join(separator)
    end
    
    def radio_buttons(field,tag_values,options = {})
      output = ""
      opts = options.clone
      opts[:class] = 'radio_button'
      separator = opts.delete(:separator) || ' &nbsp; '
      no_escape = opts.delete(:no_escape)
      tag_values.each do |val|
        if(val.is_a?(Array)) 
          if(val[1] === true || val[1] === false) 
            butt_opts = opts.clone
            obj_val = @object.send(field) if @object
            if val[1] && (obj_val  === true || obj_val === 1 || obj_val === '1')
              butt_opts[:checked] = 'checked'
            elsif !val[1] && (obj_val  === false || obj_val === 0 || obj_val === '0')
              butt_opts[:checked] = 'checked'
            end
            val[1] = val[1] ? '1' : '0'
          else
            butt_opts = opts
          end
          output += "<label class='radio_button'>" + 
            radio_button(field, val[1], butt_opts) + " " + 
            (no_escape ? val[0] : emit_label(val[0])) + 
             "</label>" + separator
        else
          output += "<label class='radio_button'>" + radio_button(field, val, opts) + " " + emit_label(val.to_s.humanize) + "</label>"+ separator 
        end
        
      end 
      output
    end

    alias_method :radio_buttons_flat, :radio_buttons

    def grouped_radio_buttons(field,tag_values,options={})
      output = ''
      tag_values.each do |header,opts|
        output += "<div class='options_header'><b>#{h(header)}</b></div>"
        output += radio_buttons_flat(field,opts,options)
      end
      output

    end
    
    def check_boxes(field,tag_values,options = {})
      output = ""
      opts = options.clone
      opts.symbolize_keys!
      opts[:class] = 'check_box'
      singular = opts.delete(:single)
      field_array = singular ? '' : "[]"
      separator = opts.delete(:separator) || ' &nbsp; '
      to_iize = opts.delete(:integer)

      output += hidden_field_tag("#{@object_name}[#{field}]#{field_array}",'',:id => "#{@object_name}_#{field}_empty") unless opts.delete(:no_blank)
      tag_values.each do |val|
        if(val.is_a?(Array)) 
          obj_val = @object.send(field) if @object
          if to_iize && obj_val && obj_val.is_a?(Array)
            obj_val = obj_val.map { |elm| elm.to_i }
          end
          if obj_val && ((obj_val.is_a?(Array) && obj_val.include?(val[1]) || obj_val == val[1] ))
            checked=true
          else
            checked=false
          end
          opts[:id] = "#{@object_name}_#{field}_#{val[1]}"
          output += "<label class='check_box'>" + 
            check_box_tag("#{@object_name}[#{field}]#{field_array}", val[1],checked,opts) + " " + 
            emit_label(val[0].to_s.gsub("\n","<br/>")).gsub("&lt;br/&gt;","<br/>") +
             "</label>" + separator
        else
          obj_val = @object.send(field) if @object 
          if obj_val && obj_val.include?(val)
            checked=true
          else
            checked=false
          end
          opts[:id] = "#{@object_name}_#{field}_#{val}"
          output += "<label class='check_box'>" + check_box_tag("#{@object_name}[#{field}]#{field_array}", val,checked,opts) + " " + emit_label(val.to_s.humanize) + "</label>"+ separator 
        end
        
      end
    
  
      output
    end

    alias_method :check_boxes_flat, :check_boxes

    def grouped_check_boxes(field,tag_values,options={})
      output = ''
      tag_values.each do |header,opts|
        output += "<div class='options_header'><b>#{h(header)}</b></div>"
        output += check_boxes_flat(field,opts,options)
      end
      output

    end    
    
    
    def submit_cancel_tags(submit_name,cancel_name,submit_options={},cancel_options={}) 
       submit_options[:class] ||= 'submit_button'
       submit_options[:name] ||= 'submit_form'
       if cancel_options.is_a?(String)
         cancel_options = { :onclick => "document.location='#{cancel_options}'; return false;" }
       end  
       cancel_options[:class] ||= 'cancel_button'
       cancel_options[:name] ||= 'cancel_form'

      @template.submit_tag(emit_label(submit_name),submit_options) + "&nbsp;&nbsp;" + @template.submit_tag(emit_label(cancel_name),cancel_options)
    end
    
    def cancel_submit_buttons(cancel_name,submit_name,cancel_options={},submit_options={}) 
       submit_options[:class] ||= 'submit_button'
       submit_options[:name] ||= 'commit'
       cancel_options[:class] ||= 'cancel_button'
       cancel_options[:name] ||= 'cancel'
       cancel_options[:onclick] = 'this.form.submit();' unless cancel_options[:onclick]
       cancel_options[:type] = 'button'
       cancel_options[:value] = emit_label(cancel_name)

      @template.tag('input',cancel_options) + "&nbsp;&nbsp;" + @template.submit_tag(emit_label(submit_name),submit_options)
    end    
    
    def emit_label(txt)
      if @frm_options[:no_translate]
        h(txt)
      elsif txt && txt == ''
        ''
      else
        h(txt.to_s.t).gsub("\n","<br/>").gsub("\\n","<br/>")
      end
    end
    
  def output_error_message(label,field)
    return nil unless @object && @object.errors
    begin
      errs = @object.errors.on(field)
    rescue Exception =>e
      raise @object.errors.inspect + errs.inspect
    end
    if errs.is_a?(Array)
      label = label.gsub(/\:$/,'') # get rid of ending : if there
      opts = errs.pop if errs.last.is_a?(Hash)
      errs.pop if errs.last.nil?
      

      errs = errs.uniq
      return errs.collect do |msg|
        msg = @object.errors.generate_message(field,msg) if msg.is_a?(Symbol)
        label + " " + emit_label(msg) + "<br/>"
      end
    elsif errs
      label = label.gsub(/\:$/,'') # get rid of ending : if there
      errs = @object.errors.generate_message(field,errs) if errs.is_a?(Symbol)
        
      return label + " " + emit_label(errs)
    end
    
    nil
  end  
 

end

class StyledForm < ActionView::Helpers::FormBuilder

  
    include StyledFormBuilderGenerator::Generator
    
    include EnhancedFormElements
    
    def initialize(object_name,object,slf,options,proc)
    	@frm_options = options.delete(:styled_form) || {}
    	super
    end
  
    
end

class SimpleForm < StyledForm
  include StyledFormBuilderGenerator::Generator
  
  include EnhancedFormElements
  
  def form_options(tag,field,output,options)
    options[:class] = options[:class] ? tag + '_input ' + options[:class] : tag + '_input '
    {
      :output => output.call( {:class => options[:class] })
    }
  end
  
  generate_styled_fields('form_options',
                         (field_helpers + %w(label_field label_option_field country_select collection_select select radio_buttons grouped_check_boxes grouped_radio_buttons grouped_select check_boxes) - %w(check_box radio_button hidden_field))) do 
                           @options[:output]
                          end
  
  generate_form_for('','')
  
  generate_form_for('','',:name => 'simple_fields',:display => true)
  
end

module TabledFormElements

  def spacer(size=nil)
    txt = size ? "<img src='/images/spacer.gif' width='1' height='#{size}' />" : '<br/>'
    "<tr><th colspan='2' align='center'>" + txt + "</th></tr>"
  end 

  def divider(tg='<hr/>')
    "<tr><th colspan='2' align='center'>" + tg + "</th></tr>"
  end 

  
  def header(name,options = {})
    cols = (options.delete(:columns) || 1)+1
    description = "<tr><td colspan='#{cols}' class='description'>#{emit_label(options[:description])}</td></tr>" if !options[:description].blank?
    "<tr><td class='header#{'_description' if description}' colspan='#{cols}'>" + super  + "#{options[:tail]}</td></tr>" + description.to_s
  end 
  
  def submit_tag(name,options = {})
    cols = (options.delete(:columns) || 1)+1
    "<tr><td colspan='#{cols}' align='right'>" + super  + "</td></tr>"
  end
  
  def image_submit_tag(name,options ={})
    cols = (options.delete(:columns) || 1)+1
    "<tr><td colspan='#{cols}' align='right'>" + super  + "</td></tr>"
  end
  
  def submit_cancel_tags(submit_name,cancel_name,submit_options={},cancel_options={})
    cols = (options.delete(:columns) || 1)+1
    "<tr><td colspan='#{cols}' align='right' nowrap='1'>" + super  + "</td></tr>"
  end
  
  def cancel_submit_buttons(cancel_name,submit_name,cancel_options={},submit_options={})
    cols = (options.delete(:columns) || 1)+1
    "<tr><td colspan='#{cols}' align='right' nowrap='1'>" + super  + "</td></tr>"
  end
  
  
  def show_error_message(field,label=nil)
   label ||= (field.to_s.humanize).t
   if error_message = output_error_message(emit_label(label),field)
      "<tr><td></td><td class='error'>#{error_message}</td></tr>"
    else
      nil
    end
  end


end

class TabledForm < StyledForm
  include StyledFormBuilderGenerator::Generator
  
  include TabledFormElements

  
  def form_options(tag,field,output,options)
    options = options.clone
    label = emit_label(options.delete(:label) || field.to_s.humanize)
    noun = emit_label(options.delete(:noun)) if options[:noun]
    options[:class] = options[:class] ? tag + '_input ' + options[:class] : tag + '_input '
    cols = options.delete(:columns) || 1
    unstyled = options.delete(:unstyled)
    description = emit_label(options.delete(:description))
    {
      :label => label,
      :control => tag,
      :unit => emit_label(options.delete(:unit) || ''),
      :tail => options.delete(:tail),
      :required => options.delete(:required),
      :vertical => options.delete(:vertical),
      :error => ( options.delete(:skip_error) ? nil : output_error_message( noun || label,field) ),
      :output => output.call( :class => options[:class] ),
      :valign => options[:valign],
      :description => description.to_s.gsub("\n","<br/>"),
      :cols => cols,
      :unstyled => unstyled
      
    }
  end
  

  def custom_field(field,options={},&block)
    opts = options.clone
    
    label = emit_label(opts.delete(:label) || field.to_s.humanize)
    noun = emit_label(opts.delete(:noun)) if options[:noun]

    error = ''
    if error_message = output_error_message( noun || label,field)
      error = "<tr><td></td><td class='error'>#{error_message}</td></tr>"
    end
    
    cols = (options.delete(:columns) || 1)
    
    
    required = opts.delete(:required) ? "*" : ""
    
    if options[:value] || !block_given?
      text = options.delete(:value) || ''
      vals = form_options('custom',field,lambda { text },options)
      vertical = options.delete(:vertical)
      if vertical
          description = "<tr><td colspan='#{cols+1}' class='description'>#{options[:description]}</td></tr>" if !options[:description].blank?
        	'<tr><td class="label_vertical" colspan="#{cols+1}">' + vals[:label] + required + '</td></tr>' + error
	        "<tr><td colspan='#{cols+1}' class='data_vertical control_#{options[:control]}'>" + vals[:output] + "</td></tr>" + description.to_s
      else
          description = "<tr><td/><td class='description'>#{options[:description]}</td></tr>" if !options[:description].blank?
      
	error + "<tr><td class='label'  valign='baseline' >" + vals[:label] + required + "</td><td class='data #{options[:control]}_control' colspan='#{cols}'>" + vals[:output] + '</td></tr>' + description.to_s
      end
    else
      vertical = options.delete(:vertical)
      label = options.delete(:label) || field.to_s.humanize
      if vertical
          description = "<tr><td colspan='#{cols+1}' class='description'>#{options[:description]}</td></tr>" if !options[:description].blank?
	@template.concat("<tr><td colspan='#{cols+1}' class='label_vertical'>" + emit_label(label) + required + '</td></tr>' + error + "<tr><td colspan='#{cols+1}' class='data " + options[:control].to_s + "_control'>")
      else
         description = "<tr><td/><td class='description' colspan='#{cols}'>#{options[:description]}</td></tr>" if !options[:description].blank?
        @template.concat(error + '<tr><td  class="label" valign="baseline" >' + emit_label(label) + required + "</td><td class='data' colspan='#{cols}' valign='baseline'>")
      end
      yield
      @template.concat("</td></tr>" + description.to_s)
    end
  end

  generate_styled_fields('form_options',
                         (field_helpers + %w(label_field label_option_field country_select collection_select select radio_buttons check_box check_boxes grouped_check_boxes grouped_radio_buttons grouped_select ) - %w(radio_button hidden_field))) do 
                          field(@options)
                          end
                          
  def hidden_field(field,options = {})
    super
  end
                         
  generate_form_for('<table class="styled_table">','</table>')
  generate_fields_for('<table class="styled_table">','</table>',:name => 'tabled_fields', :display => true)
  generate_fields_for("","",:name => 'tabled_style_fields')
  
  def field(options)
    if options[:unstyled]
      return options[:output]
    end
    
    cols = (options[:cols] || 1)
    if options[:vertical]
      description = "<tr><td colspan='#{cols+1}' class='description_vertical'>#{options[:description]}</td></tr>" if !options[:description].blank?
      error = "<tr><td colspan='#{cols+1}' class='error'>#{options[:error]}</td></tr>" if options[:error]
    else
      description = "<tr><td/><td colspan='#{cols}' class='description'>#{options[:description]}</td></tr>" if !options[:description].blank?
      error = "<tr><td></td><td colspan='#{cols}' class='error'>#{options[:error]}</td></tr>" if options[:error]
    end
        
    valign = case options[:control]
    when 'text_area','upload_image'
      'top'
    else
      'baseline'
    end
    valign = options[:valign] if options[:valign]
    
    # Checkboxes get options wrapped around their label`
    label = nil
    label = options[:label] if options[:label] && options[:label]  != ''

    if options[:control] == 'label_field'
      if options[:vertical]
        return "<tr class='vertical' ><td colspan='2' class='label_vertical'> #{label}</td></tr>#{error}<tr><td nowrap='1' colspan='2' class='data_vertical #{options[:control]}_control'>#{options[:output]}#{options[:unit]||''}#{options[:tail]}</td></tr>#{description}"
      else
        return "#{error}<tr><td class='label' valign='baseline'>#{label}</td>
          <td class='data #{options[:control]}_control'>#{options[:output]}#{options[:unit]||''}#{options[:tail]}</td></tr>#{description}"
      end
    elsif options[:vertical]
      return "<tr class='vertical' ><td colspan='#{cols+1}' class='label_vertical'> #{label}#{(label && options[:required]) ? '*':''}</td></tr>#{error}<tr><td nowrap='1' colspan='#{cols+1}' class='data_vertical #{options[:control]}_control'>#{options[:output]}#{options[:unit]||''}#{options[:tail]}</td></tr>#{description}"
    else
      return "#{error}<tr><td nowrap='1' class='label' valign='#{valign}'>#{label}#{(label && options[:required]) ? '*':''}</td><td nowrap='1' class='data #{options[:control]}_control' colspan='#{cols}' valign='baseline'>#{options[:output]}#{options[:unit]||''}#{options[:tail]}</td></tr>#{description}"
    end
  end
  
end


class TabledDisplayForm < TabledForm
  include StyledFormBuilderGenerator::Generator
  
  def form_options(tag,field,output,options)
  	if ['label_option_field'].include?(tag)
		{
		:label => emit_label(options[:label] || field.to_s.humanize),
                :output => output.call({}),
		:control => tag
		}
  	else
  		val = @object.send(field)
  		if !val || val == ''
  			val = emit_label(options[:default] || '')
  		end
		{
		:label => emit_label(options[:label] || field.to_s.humanize),
		:output =>   val,
		:control => tag
		}
	end
  end
  
  def field(options)
    return "<tr><td #{"valign='top'" if options[:control] == 'text_area'}>#{options[:label]}: </td><td >#{options[:output]}#{options[:unit]||''}</td></tr>"
  end
  
  def radio_buttons(field,tag_values,options = {})
	label_option_field(field,tag_values,options)
  end
  
  def select(field,tag_values,options = {})
	label_option_field(field,tag_values,options)
  end
  
  generate_form_for('<table  class="styled_table">','</table>', :display => true)
  generate_fields_for('<table  class="styled_table">','</table>',:name => 'tabled_display_fields', :display => true)
  
end


class LinkEditForm < TabledDisplayForm
  include StyledFormBuilderGenerator::Generator
  
  def form_options(tag,field,output,options)
  	hsh = super
  	hsh[:output] = "<a href='javascript:void(0);' #{@frm_options[:classname] ? "class='#{@frm_options[:classname]}'" : ''} onclick='#{@frm_options[:onclick]}'>#{hsh[:output]}</a>"
  	hsh
  end
  
  generate_form_for('<table  class="styled_table">','</table>', :display => true)
  generate_fields_for('<table  class="styled_table">','</table>',:name => 'link_edit_fields', :display => true)
  
end

 
module CmsFormElements
	include ActionView::Helpers::UrlHelper
	
	def filemanager_image(field,options = {})
		fileId = @object.send(field)
		file = DomainFile.find_by_id(fileId) if fileId
		url = '/website/file/popup'
		url += "?field=#{@object_name}_#{field}"
		url += "&select=img"
		
		if file
			name = file.file_path
			thumb = file.url(:icon)
		else
			name = 'Select Image'.t
			thumb = "/images/spacer.gif"
		end
		<<-SRC
    <table><td valign='middle' align='center' style='width:32px;height:32px;border:1px solid #000000;'><img id='#{@object_name}_#{field}_thumb' src='#{thumb}' onclick='openWindow("#{url}" + "&file_id=" + $("#{@object_name}_#{field}").value,"selectFile",800,400,"yes","yes")'/></td><td valign='center' align='left'><a href='javascript:void(0);' onclick='openWindow("#{url}" + "&file_id=" + $("#{@object_name}_#{field}").value,"selectFile",800,400,"yes","yes")'>

			<span id='#{@object_name}_#{field}_name' >#{name}</span>
			</a>
	<input type='hidden' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' value='#{file.id if file}' />
	</td></tr></table>
		SRC
	end
  
  def filemanager_file(field,options = {})
    if @object
      fileId = @object.send(field)
      file = DomainFile.find_by_id(fileId) if fileId
    end
    url = '/website/file/popup'
    url_options = "?field=#{@object_name}_#{field}"
    url_options += "&select=" + ( options[:type] || 'doc' ).to_s
    
    onchange = options.delete(:onchange)
    if onchange
      onchange = "onchange='#{onchange}'"
    else
      onchange = ''
    end
    if file
      name = file.file_path
    else
      name = 'Select File'.t
    end
    <<-SRC
      <a href='javascript:void(0);' onclick='openWindow("#{url}/" + $("#{@object_name}_#{field}").value + "#{url_options}" ,"selectFile",800,400,"yes","yes")'>
      <span id='#{@object_name}_#{field}_name' >#{name}</span>
      </a>
      <input type='hidden' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' value='#{file.id if file}' #{onchange} />
    SRC
  end
  
  def content_selector(field,content_class,options = {})
    if @object
      content_id =@object.send(field)
    end
    
    content = content_class.find_by_id(content_id) if content_id
    url = '/website/selector/popup'
    url_options = "?class_name=#{content_class.to_s.underscore}&field=#{@object_name}_#{field}"
    url_options += "&content_id=#{content.id}" if content
    callback = options.delete(:callback)
    url_options += "&callback=#{CGI.escape(callback)}" if callback
    if content 
      name = content.name
    else
      name = ("Select " + (options.delete(:content_name) || content_class.to_s.humanize)).t
    end
    url_options += "&name=#{CGI.escape(name)}"
    
    <<-SRC
     <a href='javascript:void(0);' onclick='openWindow("#{url}/" + $("#{@object_name}_#{field}").value + "#{url_options}" ,"selectFile",400,260,"yes","yes")'>
      <span id='#{@object_name}_#{field}_name' >#{name}</span>
      </a>
      <input type='hidden' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' value='#{content.id if content}' />
     SRC
  end
  
  def multi_content_selector(field,content_class,options = {})
    if @object
      content_ids =@object.send(field)
    end
    
    content_objects = content_class.find(:all,:conditions => { :id => content_ids }) if content_ids
    url = '/website/selector/popup_multi'
    url_options = "class_name=#{content_class.to_s.underscore}&field=#{@object_name}_#{field}&field_name=#{@object_name}[#{field}]"
    callback = options.delete(:callback)
    url_options += "&callback=#{CGI.escape(callback)}" if callback
    if content_objects && content_objects.length > 0
      name = content_objects.map(&:name).join("<br/>")
      hidden_field_tags =  content_objects.map { |elm| "<input type='hidden' name='#{@object_name}[#{field}][]' value='#{elm.id}' />" }
    else
      name = ("Select " + (options.delete(:content_name) || content_class.to_s.humanize.pluralize)).t
    end
    url_options += "&name=#{CGI.escape(name)}"
    
    <<-SRC
     <a href='javascript:void(0);' onclick='openWindow("#{url}?content_ids=" + $$("##{@object_name}_#{field}_values input").map(function(elm) { return elm.value; }).join(",") + "&#{url_options}" ,"selectFile",400,260,"yes","yes")'>
      <span id='#{@object_name}_#{field}_name' >#{name}</span>
      </a>
      <div id='#{@object_name}_#{field}_values'>#{hidden_field_tags}</div>
     SRC
  end  
  
  def filemanager_folder(field,options = {})
    if @object
      fileId = @object.send(field)
    end
    file = DomainFile.find_by_id(fileId) if fileId
    url = '/website/file/popup'
    url_options = "?field=#{@object_name}_#{field}"
    url_options += "&select=fld"
    if file 
      name = file.file_path
    else
      name = 'Select Folder'.t
    end
    
    <<-SRC
      <a href='javascript:void(0);' onclick='openWindow("#{url}/" + $("#{@object_name}_#{field}").value + "#{url_options}" ,"selectFile",800,400,"yes","yes")'>
      <span id='#{@object_name}_#{field}_name' >#{name}</span>
      </a>
      <input type='hidden' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' value='#{file.id if file}' />
    SRC
  end
	
  def color_field(field,options = {}) 
    color = @object.send(field)
    color ||= ''
    
    <<-SRC
      #{tag('input',options.merge(:name => "#{@object_name}[#{field}]", :id => "#{@object_name}_#{field}", :value => color, :size => 15, :onchange => "SCMS.updateColorField('#{@object_name}_#{field}');"  ) )}
      <a href='javascript:void(0);'
        onclick='if(!$("#{@object_name}_#{field}").disabled) SCMS.pickerWindow("/javascripts/pickers/color.htm",{cur_color:"#{color}",callback:"#{@object_name.to_s+'_'+field.to_s}"}, {width: 250, height: 150 })' id='#{@object_name}_#{field}_color' style='border:1px solid #000000; 
        #{"background-color:#{color};" unless color=='' }'>
        <img src='/images/spacer.gif' width='16' height='16' />
        </a>
    SRC
  end
  
  def date_field(field,options = {})
    date_value = @object.send(field) if @object
    if date_value.is_a?(String)
      date_txt = date_value
    elsif date_value || !options.delete(:blank)
      date_txt = (date_value || Time.now).localize("%m/%d/%Y".t)
    else
      date_txt = ''
    end
    url = '/website/public/calendar' 
    <<-SRC
      #{tag('input',options.merge(:name => "#{@object_name}[#{field}]", :id => "#{@object_name}_#{field}",:class => "date_field", :value => date_txt, :size => 15 ) )}
      <a href='javascript:void(0);'
        onclick='if(!$("#{@object_name}_#{field}").disabled) SCMS.pickerWindow("#{url}",{date: $("#{@object_name}_#{field}").value, callback:"#{@object_name.to_s+'_'+field.to_s}"}, {width: 250, height: 180 })' id='#{@object_name}_#{field}_date'>
        <img src='/images/calendar.gif' width='16' height='16' align='absmiddle' border='0'/>
        </a>
    
    SRC
  
  end
  
  def datetime_field(field,options = {})
  
    date_value = @object.send(field) if @object
    if date_value.is_a?(String)
      date_txt = date_value
    elsif date_value || !options.delete(:blank)
      date_txt = (date_value || Time.now).localize("%m/%d/%Y %H:%M".t)
    else
      date_txt = ''
    end
    
    url = '/website/public/calendar' 
    <<-SRC
      #{tag('input',options.merge(:name => "#{@object_name}[#{field}]", :id => "#{@object_name}_#{field}", :value => date_txt ) )}
      <a href='javascript:void(0);'
        onclick='if(!$("#{@object_name}_#{field}").disabled) SCMS.pickerWindow("#{url}",{date: $("#{@object_name}_#{field}").value, show_time:true,  callback:"#{@object_name.to_s+'_'+field.to_s}"}, {width: 250, height: 200 })' id='#{@object_name}_#{field}_date'>
        <img src='/images/calendar.gif' width='16' height='16' align='absmiddle' border='0' />
        </a>
    
    SRC
  end
  
  def editor_area(field,options = {})
    txt = @object.send(field)
    
    options = options.clone
    options[:class] = 'cmsFormMceEditor'
    options[:style] = 'width:100%;' unless options[:style]
    tpl = options.delete(:template)
      
    

    txtarea = self.send(:text_area,field,options)
    
    elem_id = "#{@object_name}_#{field}"
    
    if tpl
      @content_css = "/stylesheet/#{tpl}.css"
      @design_styles = SiteTemplate.css_design_styles(tpl,'en')
    end
    if options[:inline]
    js = <<-EOF
      <script>
        if(!mceDefaultOptions) {
          var mceDefaultOptions = {
          theme : "advanced",
          theme_advanced_layout_manager: "SimpleLayout",
          auto_reset_designmode : true,
          mode : "none",
          valid_elements: "*[*]",
          plugins: 'table,filemanager,advimage,advlink,flash,paste',
          extend_valid_elements: 'a[name|href|target|title|onclick]',
          theme_advanced_buttons1 : "bold,italic,underline,separator,strikethrough,justifyleft,justifycenter,justifyright,justifyfull,bullist,numlist,outdent,indent,undo,redo,pastetext,pasteword,anchor,link,unlink,image,filemanager,hr",
          theme_advanced_buttons2 : "forecolor,backcolor,formatselect,fontselect,fontsizeselect,styleselect",
          theme_advanced_blockformats: "p,div,h1,h2,h3,h4,h5,h6,blockquote,dt,dd,code,samp",
          theme_advanced_buttons3 : "flash,tablecontrols,code",
          theme_advanced_toolbar_location : "top",
          theme_advanced_toolbar_align: 'left',
          external_link_list_url: "/website/edit/links",
          debug : false,
          relative_urls : false,
      	  remove_script_host : true,
      	  body_class : 'monthly_tip',
          image_insert_url: "/website/file/manage",
          
          theme_advanced_styles : "#{@design_styles.collect { |style| "#{style.humanize.capitalize}=#{style}" }.join(";")}", 
          external_link_list_url: "/website/edit/links",
          theme_advanced_toolbar_align: 'left',
          #{ "content_css: '#{@content_css}'" if @content_css },
          debug : false,
          relative_urls : false,
      	  remove_script_host : true,          
          

       };
             
      try {
        if(cmsEditorOptions) {
          mceDefaultOptions = Object.extend(mceDefaultOptions,cmsEditorOptions)
        }
      }
      catch(err) {  }
      tinyMCE.init(mceDefaultOptions);    
      }
      Event.observe( window, 'load',function() { tinyMCE.execCommand('mceAddControl',true,'#{elem_id}'); } );
      </script>
    EOF
    txtarea += js
    end
    txtarea
  end
  
  def upload_image(field,options = {})
    image_file_id =  @object.send(field)
    image_file = DomainFile.find_by_id(image_file_id)
    no_label = options[:no_label]
    current_image= nil
    if image_file && !image_file.url.to_s.empty?
      current_image = <<-IMAGE_SOURCE
      <a href='javascript:void(0);' onclick='document.getElementById("#{@object_name}_#{field}_clear").value="0"; this.innerHTML = "";'  style='display:block;width:66px;height:66px;text-align:center;border:1px solid #CCCCCC;padding:0px;margin;0px;'>
      <img src='#{image_file.url(:thumb)}' style='padding:0px;margin:0px;border:0px;' title='Click to remove image' />
      </a>
    IMAGE_SOURCE
   end
    <<-SRC
      <table cellpadding='0' cellspacing='0'><tr><td>
      #{current_image}</td><td>
      #{("Upload Image".t + ":<br/>") unless no_label }
      <input type='hidden' name='#{@object_name}[#{field}_clear]' id='#{@object_name}_#{field}_clear' value='#{image_file ? image_file.id : ''}' />
      <input type='file' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' />
      </td></tr></table>
    SRC
  
  end
  
  def upload_document(field,options = {})
    doc_file_id =  @object.send(field)
    doc_file = DomainFile.find_by_id(doc_file_id)
    maxlength = options.delete(:maxlength)
    maxlength = "maxlength='#{maxlength}'" if maxlength
    current_doc= nil
    if doc_file && !doc_file.url.to_s.empty?
      current_doc = <<-DOC_SOURCE
      <a href='#{doc_file.url}' target='_blank' >
      <img src='/images/site/document.gif' style='width:16px;height:16px;padding:0px;margin:0px;border:0px;' />
      #{h doc_file.name}
      </a><br/>
    DOC_SOURCE
   end
    <<-SRC
      #{current_doc}
      <input type='file' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' #{maxlength}/>
    SRC
  
  end


  def unsorted_selector(field,available_values,selected_values,options = {})

    <<-SRC
    <script>
      var #{field.to_s}_editor  = {
        options: new Array(  #{available_values.collect { |elem| "[\"#{elem[0]}\",\"#{elem[1]}\"]" }.join(",") } ),

        updateSelectors: function() {

          var values = $("#{@object_name}_#{field}").value.split("|");
          $("#{@object_name}_#{field.to_s}_available_options").options.length = 0;
          
          var selectedValues = [];

          for(var i=0,len = this.options.length;i < len;i++) {
              var opt = this.options[i];
              if(opt[1] == '' || values.indexOf(opt[1]) == -1) {
                $("#{@object_name}_#{field.to_s}_available_options").options.add(new Option(this.options[i][0],this.options[i][1]));
              }
              else if(opt[1] != '') {
                  selectedValues.push(opt);
              }
          }
          var displayElem = $('#{@object_name}_#{field}_display');
          displayElem.innerHTML = '';
          for(var k=0,len = selectedValues.length;k<len;k++) {
            displayElem.innerHTML += "<a href='javascript:void(0);' onclick='#{field.to_s}_editor.removeElement(\\"" + selectedValues[k][1] + "\\");'>" + selectedValues[k][0] + "</a><br/>";
          }
        },
        addElement: function() {
            var values = $("#{@object_name}_#{field}").value.split("|");
            var selected = $("#{@object_name}_#{field.to_s}_available_options").value;
            if(selected == '')
              return;
            values.push(selected);
            $("#{@object_name}_#{field}").value = values.uniq().join("|");
            this.updateSelectors();
        },
        removeElement: function(value) {
            var values = $("#{@object_name}_#{field}").value.split("|");
            values = values.without(value,'');
            $("#{@object_name}_#{field}").value = values.uniq().join("|");
            this.updateSelectors();
        }
      }
    </script>
    <input type='hidden' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' value="#{selected_values.collect { |elem| elem[1] }.join("|")}" />
    <select name='#{@object_name}_#{field.to_s}_available_options' id='#{@object_name}_#{field.to_s}_available_options'></select>
    <button onclick='#{field.to_s}_editor.addElement(); return false;'>Add</button><br/>
    <div size='#{options[:size]||5}' id='#{@object_name}_#{field}_display' style='border:1px solid; height:6em; overflow:auto;'>
    </div>
    <script>#{field.to_s}_editor.updateSelectors();</script>

    SRC
  end
 
 
      
  def price_range(field, prices, opts = {})
  
    object_name = @object_name
    field_values = @object.send(field)
    price_values = @object.send(prices)
    field_name = field.to_s
    price_name = prices.to_s
    options = { :field => field.to_s, 
                :field_units => opts[:field_units],
                :measure => opts[:measure] || 'units', 
                :units => opts[:units] || 'lbs', 
                :currency => opts[:currency] || ['$',''] 
              }
    
    <<-SRC
    <script>
     #{object_name}_#{field_name}_editor = {
          
      changedUnit: function(elem) {
        if(elem.value != '' && !(Number(elem.value) > 0.0)) {
          alert('#{"Please enter a valid %s" / options[:measure]}');
          elem.select();
          setTimeout(function() {elem.focus(); },10);
          return;
        }
        else {
          if(elem.value != '')
            elem.value = Number(elem.value).toFixed(#{options[:field_units] || 1});
          this.updateUnits();
        
        }
      },
      
      changedPrice: function(elem) {
        elem.value = Number(elem.value).toFixed(2);
      
      },
      
      updateUnits: function() {
        var i=0;
        var units = [];
        while($('#{object_name}_#{field_name}_' + i)) {
          units.push({ unit: $('#{object_name}_#{field_name}_' + i).value,
                         price: $('#{object_name}_#{price_name}_' + i).value })
        
          i++;
        }
        units.sort(function(a,b) {
            if(b['unit'] == '') return -10;
            if(a['unit'] == '') return 10;
            return a['unit'] - b['unit'];
          });

        if(units.length == 0 || units[units.length - 1]['unit'] != '') {
          units.push( { unit: '', price: '' } );
        }

        // Find the last non-blank one
        for(var k = units.length - 1;k > 0;k--) {
          if(units[k-1]['unit'] != '')
            break;
          else {
            this.deleteRow(k);      
            units.pop();
          }
        }
        
          
        for(i=0;i<units.length;i++) {
          if(!$('#{object_name}_#{field_name}_' + i)) {
            this.addRow('','',i);
          }
          $('#{object_name}_#{field_name}_' + i).value = units[i]['unit'];
          $('#{object_name}_#{price_name}_' + i).value = units[i]['price'];
          if(i > 0)
            $('#{object_name}_#{field_name}_min_' + i).innerHTML = units[i-1]['unit'];
        }
        
        // Delete the last two %= %
      
      },
      
      
      addRow: function(unit,price,index) {
        var last_val = Number(0.0).toFixed(#{options[:field_units] || 1});
        if(index > 0 && $('#{object_name}_#{field_name}_' + (index-1)))
            last_val = $('#{object_name}_#{field_name}_' + (index-1)).value;
            
        var rw = Builder.node('tr', { id: "#{object_name}_#{field_name}_row_" + index },
                [ Builder.node('td',{ style: 'text-align:right;' },
                   [ Builder.node('span', { id: '#{object_name}_#{field_name}_min_' + index }, last_val), " #{options[:units]}" ] ),
                  Builder.node('td', ' - '),
                  Builder.node('td',
                    [ Builder.node('input', { type:'text', size:'5', id:'#{object_name}_#{field_name}_' + index, style:'text-align:right;',
                                              name:'#{object_name}[#{field_name}][]',
                                              onchange:'#{object_name}_#{field_name}_editor.changedUnit(this); return false;',
                                              value:unit }),
                      " #{options[:units]}"]),
                  Builder.node('td',{ style:"padding-left:30px;"},
                    [ " #{options[:currency][0]}",
                      Builder.node('input', { type: 'text', style:'text-align:right;',
                                              name: '#{object_name}[#{price_name}][]',
                                              id: '#{object_name}_#{price_name}_' + index,
                                              onchange:'#{object_name}_#{field_name}_editor.changedPrice(this); return false;',
                                              size:5, value:price }),
                     "#{options[:currency][1]}" ])
                  ]);
        $("#{object_name}_#{field_name}_table").appendChild(rw);
      },
      
      deleteRow: function(index) {
        var tbl = $("#{object_name}_#{field_name}_table");
        tbl.deleteRow(index);
      }
      
   
    }    
    </script>    
    <table >
      <tbody id="#{object_name}_#{field_name}_table" >
      </tbody>
    </table>
    <script>
      #{(0..price_values.length-1).to_a.collect { |index| "#{object_name}_#{field_name}_editor.addRow('#{field_values[index]}','#{price_values[index]}',#{index});\n" } } 
      #{object_name}_#{field_name}_editor.updateUnits();
    </script>

    SRC
  end
  
  
  def price_classes(field,classes,opts = {})
  
    options = { 
                :currency => opts[:currency] || ['$',''] 
              }
  
    class_html = ''
    classes.each do |cls|
      class_html += "<tr><td>#{cls[0]}:</td>"
      class_html += "<td style='padding-left:20px;'>"
      class_html += "#{options[:currency][0]}<input style='text-align:right;' type='text' size='5' name='#{@object_name}[#{field}][#{cls[1].to_s}]'value='#{(@object.send(field)||{})[cls[1].to_s]}' onchange='this.value = Number(this.value).toFixed(2);' />#{options[:currency][1]}</td></tr>"
    end    
    <<-SRC
    <table>
      #{class_html}
    </table>
    SRC
  end
  
  def image_list(field,opts={})
    obj_name = @object_name.to_s.gsub(/\[|\]/,"_");
    
    val = @object.send(field).to_s.split(",").find_all { |elm| elm.to_i > 0 }
    if val.length > 0
      df = DomainFile.find(:all,:conditions => ["id IN (?)",val])
      
      files = df.collect do |fl|
        file_id = fl.id
        html = nil
        if fl
          html = "<div class='attachment' id='#{@object_name}_#{field}_attachment_#{fl.id}'><table><tr><td>"        
          if fl.file_type == 'doc'
            html += "<img id='#{@object_name}_#{field}_handle_item_#{fl.id}' src='#{@template.controller.theme_src("/images/icons/filemanager/document.gif")}' align='top' width='64' height='64'/>"
          elsif fl.file_type == 'img' || fl.file_type == 'thm'
            html += "<div class='fm_image' id='#{@object_name}_#{field}_handle_item_#{fl.id}' ><img src='#{fl.url(:thumb)}' align='middle' id='#{field}_thumb_image_#{fl.id}'/></div>"
          end
          html += "</td><td><a href='javascript:void(0);' onclick='image_list_#{obj_name}_#{field}.showAttachmentPopup(\"#{fl.id}\");'>#{h(fl.name)}</a></td></tr></table></div>"
        end
        html
      end
    else
      files = ""
    end
    
    
    link_txt = link_to('+Add Image'.t, "/website/file/popup?select=file&callback=image_list_#{obj_name}_#{field}.attachFile&thumb_size=thumb", :popup => ['file_manager', 'height=400,width=600,resizable=yes,scrollbars=yes' ])
    
     <<-JAVASCRIPT
        <script>
          var image_list_#{obj_name}_#{field} = {
             attachFile: function(field,type,id,path,url,thumb,name) {
                this.removeAttachment(id);
                var code = "<table><tr><td>";
                
                if(type != 'img') {
                  code +=  "<img id='handle_item_" + id + "' src='" + thumb + "' align='top' width='64' height='64'>";
                }
                else {
                  code +=  "<div class='fm_image'><img src='" + thumb + "'  align='middle'></div>";
                }
                
                code += " </td><td><a href='javascript:void(0);' onclick='image_list_#{obj_name}_#{field}.showAttachmentPopup(" + id + ");'>" + name + "</a></td></tr></table></div>";
                
                var elem = document.createElement('div');
                elem.id = '#{@object_name}_#{field}_attachment_' + id;
                elem.className="attachment";
                elem.innerHTML = code;
                
                 $('image_list_#{@object_name}_#{field}').appendChild(elem);
                this.recreateSortable();
                this.updateFieldValue();
                
              },
              
             recreateSortable: function() {
                Sortable.create('image_list_#{@object_name}_#{field}', { tag: 'div', onUpdate: image_list_#{obj_name}_#{field}.updateFieldValue  });
             },
             
             updateFieldValue: function() {
                var images = $('image_list_#{@object_name}_#{field}').select(".attachment").collect(function(elem) {
                var name = elem.id.split("_");
                return name[name.length - 1];
                });
                $('#{@object_name}_#{field}').value = images.join(",");
             },
      
             showAttachmentPopup: function(aid) {
               SCMS.popup(new Array(
                [ 'Remove Attachment', 'js', 'image_list_#{obj_name}_#{field}.removeAttachment(' + aid + ')' ]
              )); 
            },
  
            removeAttachment: function(id) {
              if($('#{@object_name}_#{field}_attachment_' + id)) {
                Element.remove('#{@object_name}_#{field}_attachment_' + id);
                this.recreateSortable();
                this.updateFieldValue();
              }
            }
          };
        </script>
        #{link_txt}
        <div id='image_list_#{@object_name}_#{field}' style='min-height:80px; border:1px solid #000000;  margin:3px;  overflow:auto;'>
        #{files}
       </div>
       <input type='hidden' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' value='#{val.join(",")}'/>
       <script>
        image_list_#{obj_name}_#{field}.recreateSortable();
       </script>
    JAVASCRIPT
  
  end
  
  
  def end_user_selector(field,opts = {})
      
      if opts[:no_name]
        id_field = field
        field = "#{id_field}_name"
      else
        id_field = opts[:id_field] || "#{field}_id"
      end
      
      if id_field
        id_value = @object ? @object.send(id_field) : ''
        usr = EndUser.find_by_id(id_value)
        if usr
          value = usr.name
        elsif !opts[:no_name]
          value = @object ? @object.send(field) : ''
        end
      else
        value = @object ? @object.send(field) : ''
      end
      
      field_id = "#{@object_name}_#{field}"
      if opts[:no_name]
        field_name = "#{@object_name}_#{field}_selector"
      else
        field_name = "#{@object_name}[#{field}]"
      end
      
      id_field_id = "#{@object_name}_#{id_field}"
      ok_icon_id = "#{@object_name}_#{field}_ok"
      id_field_name = opts[:id_field_name] || "#{@object_name}[#{id_field}]"


      
       <<-JAVASCRIPT
        <span class='data text_field_control'><input type='text' style='width:280px;' id='#{field_id}' name='#{field_name}' class='text_field' value='#{h value}' onkeyup="if($('#{id_field_id}_temp').value != this.value) { $('#{id_field_id}').value=''; $('#{ok_icon_id}').style.visibility='hidden'; }" />
    <input type='hidden' name='#{id_field_name}' value='#{id_value}' id='#{id_field_id}'/>
    <input type='hidden' value='' id='#{id_field_id}_temp'/>
    <img src='#{@template.controller.theme_src('icons/ok.gif')}' id='#{ok_icon_id}' style='#{"visibility:hidden;" unless usr}' /></span>
    <div class='autocomplete' id='#{field_id}_autocomplete' style='display:none;' ></div>
    
    <script>
      var autocomplete = new Ajax.Autocompleter('#{field_id}','#{field_id}_autocomplete','#{@template.controller.url_for(:controller => '/members', :action => 'lookup_autocomplete')}',{ minChars: 2, paramName: 'member', afterUpdateElement: function(text,li) { 
        $('#{field_id}').value = li.select(".name")[0].innerHTML; 
        $('#{id_field_id}_temp').value = li.select(".name")[0].innerHTML; 
        $('#{ok_icon_id}').style.visibility='visible';
        $('#{id_field_id}').value = SCMS.getElemNum(li);
        }
      });
    </script>
      
  JAVASCRIPT
  end
    
  def autocomplete_field(field,url,opts = {})

          
      value = @object ? @object.send(field) : ''
      
      field_id = "#{@object_name}_#{field}"
      if opts[:no_name]
        field_name = "#{@object_name}_#{field}_selector"
      else
        field_name = "#{@object_name}[#{field}]"
      end
      
      multiple = opts.delete(:multiple)
      callback = opts.delete(:callback)
    
      type = opts.delete(:type) || 'text'
      if type == 'text'
        text_field = tag(:input,{:type=>'text',:style => 'width:280px;',
          :id => field_id,:name => field_name,:class=>'text_field',:value => h(value) }.merge(opts.delete(:html) || {}))
      elsif type=='textarea'
        text_field = content_tag(:textarea,h(value), {:style => 'width:280px;',
          :id => field_id,:name => field_name,:class=>'text_field' }.merge(opts.delete(:html) || {}))
      end
       <<-JAVASCRIPT
        <span class='data text_field_control'>#{text_field}</span>
        <div class='autocomplete' id='#{field_id}_autocomplete' style='display:none;' ></div>
      
    <script>
      var autocomplete = new Ajax.Autocompleter('#{field_id}','#{field_id}_autocomplete','#{url}',{ minChars: 3, paramName: '#{field_id}', #{"tokens: ','," if multiple} select: 'display_value' #{",afterUpdateElement: #{callback}" if callback}
      });
    </script>
  JAVASCRIPT
  
  end
  
 
  def page_selector(field,opts = {})
    self.select(field,[['--Select Page--'.t,nil]] + SiteNode.page_options,opts)
  end


  def ordered_array(field,opts,options={})
    objects = @object.send(field)
    
    # options for select doesn't support disabled arguments, so ryo
    select_options = ([['--Select--'.t,nil]] + opts).map do |opt|
      opt_disabled = objects.include?(opt[1]) ? 'disabled="disabled"' : ''
      "<option value='#{opt[1]}' #{opt_disabled}>#{h(opt[0])}</option>"
    end.join

    opts_hash = {}
    opts.each { |elm| opts_hash[elm[1]] = elm[0].to_s }
    
    obj_name = @object_name.to_s.gsub(/\[|\]/,"_");
    idx=-1
    existing_options = objects.map do |elm|
      idx+=1
      <<-TXT
      <div class='ordered_selection_list_item' id='#{obj_name}_#{field}_element_#{idx}'>
<div class='ordered_selection_list_remove'><a href='javascript:void(0);' onclick='OrderedArray.delete("#{obj_name}_#{field}","#{@object_name}[#{field}]","#{idx}","#{ elm}");'>X</a></div><div class='ordered_selection_list_value' id='ordered_selection_list_item_#{elm}'>#{h opts_hash[elm]}</div>
       </div>
TXT
    end.join
      
    html = <<-HTML
<script>
  OrderedArray = {
     add:function(name,obj_name) {
       var idx= $(name + "_select").selectedIndex;

       if(idx!=0) {	    
        var option = $(name + "_select").options[idx];

        if(!option.value) return;
        option.disabled = true;
        
        $(name + "_select").selectedIndex = 0;

        var existing =  $(name + "_selector").select(".ordered_selection_list_item");
        var index =1;
        if(existing.length > 0) {
          index = existing.map(function(elm) { return SCMS.getElemNum(elm.id); }).max() + 1;
        }
           
        var html = "<div class='ordered_selection_list_item' id='" + name + "_element_" + index + "'>";
        html += "<div class='ordered_selection_list_remove'><a href='javascript:void(0);' onclick='OrderedArray.delete(\\"" + name + "\\",\\"" + obj_name + "\\",\\"" + index +  "\\",\\"" + option.value + "\\");'>X</a></div>";
        html += "<div class='ordered_selection_list_value' id='ordered_selection_list_item_" + option.value + "'>" +  option.text.escapeHTML() + "</div>";
        html +="</div>";
        $(name + '_selector').insert(html);
        $(name + '_selector').show();

  
        OrderedArray.createSortables(name,obj_name);
      }
			
     },

     createSortables:function(name,obj_name) {
       Sortable.create($(name + "_selector"),{
               tag: 'div',
               constraint: 'vertical',
               dropOnEmpty: true,
               onUpdate: function() { OrderedArray.refreshPositions(name,obj_name); }
       });
       OrderedArray.refreshPositions(name,obj_name);
     },

    refreshPositions:function(name,obj_name) {
        $(name + "_positions").innerHTML = null;
        var elems = $(name + "_selector").select('.ordered_selection_list_value');

        output = "";
        var reg = /^ordered_selection_list_item_/
      
         elems.each(function(elem) {
           var str = elem.id.replace(reg, "")
           output += "<input type='hidden' name='" + obj_name + "[]' value='" + str.escapeHTML() +  "'/>"; 
         });

         $(name + "_positions").innerHTML = output;

    },


    delete: function(name,obj_name,index,obj_id) {
      $(name + '_element_' + index).remove();
      var opts = $(name + "_select").options;

      for(var i=0;i<opts.length;i++) {
        if(opts[i].value == obj_id)
            opts[i].disabled = false;
      }
       OrderedArray.refreshPositions(name,obj_name);
    }
	
   }
</script>
      <select name='#{obj_name}_#{field}_select' id='#{obj_name}_#{field}_select'>#{select_options}</select>
      <button onclick='OrderedArray.add("#{obj_name}_#{field}","#{@object_name}[#{field}]"); return false;' >Add</button><br/>
      <div id='#{obj_name}_#{field}_positions'></div>
      <div class='ordered_selection_list' id='#{obj_name}_#{field}_selector' #{"style='display:none;'" if objects.length == 0}>
        #{existing_options}
      </div>
#{    "<script>OrderedArray.createSortables('#{obj_name}_#{field}','#{@object_name}[#{field}]');</script>"}
HTML
         
  end

  
  def ordered_selection_list(field,class_name,options={})

    opts = options.delete(:options)
    opts = class_name.select_options if !opts

    id_field = options.delete(:id_field)
    id_field = class_name.to_s.underscore + "_id" unless id_field

    sortable = options.has_key?(:sortable) ? options.delete(:sortable) : true

    if sortable 
      position_field = options.delete(:position_field)
      position_field = "position" unless position_field
    end

    objects = @object.send(field)

    disabled = objects.map(&id_field.to_sym)

    # options for select doesn't support disabled arguments, so ryo
    select_options = ([['--Select--'.t,nil]] + opts).map do |opt|
      opt_disabled = disabled.include?(opt[1]) ? 'disabled="disabled"' : ''
      "<option value='#{opt[1]}' #{opt_disabled}>#{h(opt[0])}</option>"
    end.join

    obj_name = @object_name.to_s.gsub(/\[|\]/,"_");

    idx=-1
    existing_options = @object.send(field).map do |elm|
      idx+=1
      <<-TXT
 <input type='hidden' name='#{@object_name}[#{field}][][#{id_field}]' value='' />
 #{"<input type='hidden' name='#{@object_name}[#{field}][][#{position_field}]' value='' />" if sortable}
      <div class='ordered_selection_list_item' id='#{obj_name}_#{field}_element_#{elm.send(id_field)}'>
<div class='ordered_selection_list_remove'><a href='javascript:void(0);' onclick='OrderedList.delete("#{obj_name}_#{field}", "#{elm.send(id_field)}");'>X</a></div>
           #{h elm.name}
           <input type='hidden' name='#{@object_name}[#{field}][][#{id_field}]' value='#{elm.send(id_field)}' />
           #{"<input type='hidden' name='#{@object_name}[#{field}][][#{position_field}]' value='#{elm.send(position_field)}' />" if sortable}
       </div>
TXT
    end.join
      
    html = <<-HTML
<script>
  OrderedList = {
     add:function(name,obj_name,id_field,position_field) {
       var idx= $(name + "_select").selectedIndex;

       if(idx!=0) {	    
        var option = $(name + "_select").options[idx];

        if(!option.value) return;
        option.disabled = true;
        
        $(name + "_select").selectedIndex = 0;

           
        var position = $(name + '_selector').select(".ordered_selection_list_item").length + 1;
 
        var html = "<div class='ordered_selection_list_item' id='" + name + "_element_" + option.value + "'>";
        html += "<div class='ordered_selection_list_remove'><a href='javascript:void(0);' onclick='OrderedList.delete(\\"" + name + "\\",\\"" + option.value + "\\");'>X</a></div>";
        html +=  option.text;
        html += "<input type='hidden' name='" + obj_name + "[][" + id_field + "]' value='" + option.value + "'/>";
        if(position_field)
           html += "<input type='hidden' name='" + obj_name + "[][" + position_field + "]' value='" + position  + "'/>";
        html +="</div>";
        $(name + '_selector').innerHTML += html;
        $(name + '_selector').show();

  
        if(position_field) OrderedList.createSortables(name,obj_name);
      }
			
     },

     createSortables:function(name,obj_name) {
       Sortable.create($(name + "_selector"),{
               tag: 'div',
               constraint: 'vertical',
               dropOnEmpty: true,
               onUpdate: function() { OrderedList.refreshPositions(name); }
       });
     },


    delete: function(name,obj_id) {
      $(name + '_element_' + obj_id).remove();
      var opts = $(name + "_select").options;

      for(var i=0;i<opts.length;i++) {
        if(opts[i].value == obj_id)
            opts[i].disabled = false;
      }

      OrderedList.refreshPositions(name);

    },

    refreshPositions: function(name) {
      var selector = $(name + '_selector');
      var elements = selector.select('.ordered_selection_list_item');
      for(var i=0;i<elements.length;i++) {
        elements[i].select('input')[1].value = i+1;
      }

    }
   }
</script>
      <select name='#{obj_name}_#{field}_select' id='#{obj_name}_#{field}_select'>#{select_options}</select>
      <button onclick='OrderedList.add("#{obj_name}_#{field}","#{@object_name}[#{field}]","#{id_field}","#{position_field}"); return false;' >Add</button><br/>
      <div class='ordered_selection_list' id='#{obj_name}_#{field}_selector' #{"style='display:none;'" if objects.length == 0}>
        #{existing_options}
      </div>
#{    "<script>OrderedList.createSortables('#{obj_name}_#{field}','#{@object_name}[#{field}]');</script>" if sortable}
HTML
     

  end


  def access_control(field,message,options={})

    options = options.clone
    options.symbolize_keys!
    options[:single] = true

    output = ""
    opts = options.clone
    opts.symbolize_keys!
    opts[:class] = 'check_box'
    opts[:onclick] = "$('#{@object_name}_#{field}_access').style.display = this.checked ? '' : 'none';"

    output += hidden_field_tag("#{@object_name}[#{field}]",'',:id => "#{@object_name}_#{field}_empty")

    
    checked = @object.send("#{field}?") if @object

    output += "<label class='check_box'>" + 
      check_box_tag("#{@object_name}[#{field}]", 1,checked,opts) + " " + 
      emit_label(message.to_s.gsub("\n","<br/>")).gsub("&lt;br/&gt;","<br/>") +
      "</label>"
    output += "<br/>"

    display = checked ? "" : "style='display:none;'"
    output += "<div id='#{@object_name}_#{field}_access' #{display}>"
    available_actors = Role.authorized_options(true)
    output += ordered_selection_list_original("#{field}_authorized",UserClass,:id_field => 'identifier',:options => available_actors,:sortable => false)
    output += "</div>"

  end
    
end

class CmsForm < TabledForm

  include CmsFormElements
  generate_styled_fields('form_options',
                          %w(access_control filemanager_image filemanager_folder filemanager_file price_classes price_range color_field date_field datetime_field upload_image upload_document unsorted_selector content_selector multi_content_selector image_list end_user_selector autocomplete_field ordered_selection_list ordered_array)) do 
                          field(@options)
                          end

  generate_form_for('<table class="styled_table">','</table>')
  generate_fields_for('<table class="styled_table">','</table>',:name => 'cms_fields')
  generate_fields_for('','',:name => 'cms_subfields')
  generate_fields_for('<table  class="styled_table">','</table>',:name => 'cms_display_fields', :display => true)


end

class CmsUnstyledForm < StyledForm
  include StyledFormBuilderGenerator::Generator
  
  include CmsFormElements
  include EnhancedFormElements

 
  
  generate_styled_fields('form_options',
                          field_helpers + %w(label_field label_option_field country_select collection_select select radio_buttons grouped_check_boxes grouped_radio_buttons grouped_select check_boxes) - %w(check_box radio_button hidden_field) +  %w(access_control filemanager_image filemanager_folder filemanager_file price_classes price_range color_field date_field datetime_field upload_image upload_document unsorted_selector content_selector multi_content_selector image_list end_user_selector autocomplete_field ordered_selection_list ordered_array)) do 
      options[:output]
  end
  
  def form_options(tag,field,output,options)
    options[:class] = !options[:class].blank? ? tag.to_s + '_input ' + options[:class].to_s : tag.to_s + '_input'
    {
      :output => output.call( {:class => options[:class] })
    }
  end
  
 def output_error_message(label,field)
    return nil unless @object && @object.errors
    val = super
    "<div class='fieldErrMessage'>#{val}</div>" if val
  end    

  generate_form_for('','')
  generate_fields_for('','',:name => 'cms_unstyled_fields')
  
end
  




