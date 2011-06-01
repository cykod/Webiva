# Copyright (C) 2009 Pascal Rettig.

# Form For generator for creating different styled forms
module StyledFormBuilderGenerator #:nodoc:
        

  module FormFor #:nodoc:all

  end

  module Generator #:nodoc:
    module ClassMethods
      
      # Meta method which wraps a fields in a in a wrapper method,
      # allowing different styled of forms
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
              self.send("#{fld}_original",field,*args)
            end
            
            # We are going to mutate this in the options_func
            # to prevent the field from getting a whole bunch of 
            # useless attributes (:required,:vertical,etc)
            if args[-1].is_a?(Hash)
              options = args[-1] = args[-1].clone
            else
              options = { }
            end
            
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
          
	  pre = pre.blank? ? '' : pre.gsub(/([\"\#])/, '\\\\\1')
	  post = post.blank? ? '' : post.gsub(/([\"\#])/, '\\\\\1')
	  pre_cmd = pre.blank? ? '' : "concat(\"#{pre}\")"
	  post_cmd = post.blank? ? '' : "concat(\"#{post}\")"

          names = [ [ name, 'form_tag(options.delete(:url) || {}, options.delete(:html) || {})'] ]
          names << [ 'remote_' + name, 'form_remote_tag(options)' ]  unless display_only || options[:no_remote]
          names.each do |nm|
            src = <<-END_SRC 
              def #{nm[0]}_for(object_name,*args,&proc)
                raise ArgumentError, "Missing block" unless block_given?
                options = args.last.is_a?(Hash) ? args.pop : {}
                #{"concat(" + nm[1] + ")" unless display_only}
                #{pre_cmd}
                fields_for(object_name, *(args << options.merge(:builder => #{class_name})), &proc)
                #{post_cmd}
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
      
      # Generates fields for, see generate_form_for for more details
      def generate_fields_for(pre='',post='',options = {})
		    class_name = self.to_s
		    display_only = options[:display]  || false
		    name = options[:name] || class_name.underscore
		    pre = pre.blank? ? '' : pre.gsub(/([\"\#])/, '\\\\\1')
		    post = post.blank? ? '' : post.gsub(/([\"\#])/, '\\\\\1')
		    pre_cmd = pre.blank? ? '' : "concat(\"#{pre}\")"
		    post_cmd = post.blank? ? '' : "concat(\"#{post}\")"
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
    
    def self.included(mod) # :nodoc:
      mod.class_eval do
        extend ClassMethods
      end 
    end
  end
  
  
  
end


# A set of enhanced (but not CMS specific form elements)
module EnhancedFormElements
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::AssetTagHelper
 
  
    class TranslatedCountries #:nodoc:all
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

    # Returns a list of translated countries, caching the translations
    # if possible
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
    
    def country_select(field,options={})
      select_options = options.clone
      priority_countries = select_options.delete(:priority_countries) || ['United States']
      choices = translated_countries_for_select priority_countries
      obj_val = @object.send(field) if @object
      name = "#{@object_name}[#{field}]"
      opts = @template.options_for_select(choices,obj_val)
      select_tag(name,opts,select_options)
    end

    # Overrides default by adding a submit_button class
    def submit_tag(name,options = {}) 
      options[:class] ||= 'submit_button'
      options[:id] ||= object_name.to_s + "_submit"
      @template.submit_tag(emit_label(name), options)
    end
    
    # Overrides default by adding a image_submit_button class
    def image_submit_tag(src,options = {})  
      options[:class] ||= 'image_submit_button'
      @template.image_submit_tag(src, options)
    end
    
    # Just outputs a string 
    def header(name,options = {})
      emit_label(name)
    end 
    
    # Outputs a line break
    def spacer()
      '<br/>'
    end
    
    # Displays the value of a attribute of the form object
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
    
    # Custom field prototype that outputs a :value or a block
    def custom_field(field,options={},&block)
      if options[:value]
        options[:value] || ''
      else
        yield
      end    
    end
    
    # Field that outputs a the display name of an option 
    def label_option_field(field,tag_values,options={})
      val = @object.send(field)
      tag_values.each do |fld|
      	if val.to_s == fld[1].to_s
      		return fld[0]
      	end
      end
      return options[:default] || ''
    end
    
    # Grouped select, displays optheader groups using grouped_options_for_select
    def grouped_select(field,choices,options ={}, html_options = {})
      obj_val = @object.send(field) if @object

      if html_options[:multiple]
        obj_val = [obj_val] unless obj_val.is_a?(Array)
        obj_val = obj_val.map(&:to_i) if options.delete(:integer)
      end

      opts = @template.grouped_options_for_select(choices,obj_val)

      name = "#{@object_name}[#{field}]"
      select_tag(name,opts,html_options)
    end

    # Displays multiple selects, can be used like checkboxes to assign multiple values
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

    def yes_no(field,opts = {}) 
      radio_buttons(field,[['Yes'.t,true],['No'.t,false]],opts)
    end

    # Displays multiple selects, with grouped options
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
    
    # Displays a list of labeled radio buttons
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

    # Displays a list of grouped radio buttons, each set separated by a option_header div
    def grouped_radio_buttons(field,tag_values,options={})
      output = ''
      tag_values.each do |header,opts|
        output += "<div class='options_header'><b>#{h(header)}</b></div>"
        output += radio_buttons_flat(field,opts,options)
      end
      output

    end
    
    # Displays a list of checkboxes for a multi-value select
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

    # Displays a set of grouped checkboxes separated by option_header div
    def grouped_check_boxes(field,tag_values,options={})
      output = ''
      tag_values.each do |header,opts|
        output += "<div class='options_header'><b>#{h(header)}</b></div>"
        output += check_boxes_flat(field,opts,options)
      end
      output

    end    
    
    # deprecated
    def submit_cancel_tags(submit_name,cancel_name,submit_options={},cancel_options={})  #:nodoc:
       submit_options[:class] ||= 'submit_button'
       submit_options[:name] ||= 'submit_form'
       if cancel_options.is_a?(String)
         cancel_options = { :onclick => "document.location='#{cancel_options}'; return false;" }
       end  
       cancel_options[:class] ||= 'cancel_button'
       cancel_options[:name] ||= 'cancel_form'

      @template.submit_tag(emit_label(submit_name),submit_options) + "&nbsp;&nbsp;" + @template.submit_tag(emit_label(cancel_name),cancel_options)
    end
    
    # Displays a set of buttons, one of which is a submit and the other of which is a button
    def cancel_submit_buttons(cancel_name="Cancel",submit_name="Submit",cancel_options={},submit_options={}) 
       submit_options[:class] ||= 'submit_button'
       submit_options[:name] ||= 'commit'
       submit_options[:id] ||= "#{object_name}_commit_button"
       cancel_options[:class] ||= 'cancel_button'
       cancel_options[:name] ||= 'cancel'
       cancel_options[:onclick] = 'this.form.submit();' unless cancel_options[:onclick]
       cancel_options[:type] = 'button'
       cancel_options[:id] ||= "#{object_name}_cancel_button"
       cancel_options[:value] = emit_label(cancel_name)

      @template.tag('input',cancel_options) + "&nbsp;&nbsp;" + @template.submit_tag(emit_label(submit_name),submit_options)
    end    
    
    # Emits a label - translated and turning newlines into line break
    def emit_label(txt)
      if @frm_options[:no_translate]
        h(txt)
      elsif txt && txt == ''
        ''
      else
        h(txt.to_s.t).gsub("\n","<br/>").gsub("\\n","<br/>")
      end
    end
    
    # Output the error message for a specific field given a label and the field
    def output_error_message(label,field)
      return nil unless @object && @object.errors
      errs = @object.errors.on(field)
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

class StyledForm < ActionView::Helpers::FormBuilder #:nodoc:all

  
    include StyledFormBuilderGenerator::Generator
    
    include EnhancedFormElements
    
    def initialize(object_name,object,slf,options,proc)
    	@frm_options = options.delete(:styled_form) || {}
    	super
    end
  
    
end

class SimpleForm < StyledForm # :nododc:all
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

# Module that replaces some of the default styled form elements with 
# versions that site inside of a table
module TabledFormElements 

  def spacer(size=nil)
    txt = size ? "<img src='/images/spacer.gif' width='1' height='#{size}' />" : '<br/>'
    "<tr><th colspan='2' align='center'>" + txt + "</th></tr>"
  end 

  def divider(tg='<hr/>')
    "<tr><th colspan='2' align='center'>" + tg + "</th></tr>"
  end 


  def section(name=nil,options = { },&block)
    if block_given?
      @template.concat(tag("tbody",:id => name))
      yield
      @template.concat("</tbody>")
    else
      output = tag("tbody",:id => name)
      if !options.has_key?(:display) || options[:display]
        output << @template.render(:partial => options[:partial], :locals => options[:locals])
      end
      output << "</tbody>"
      output
    end
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
  
  def cancel_submit_buttons(cancel_name="Cancel",submit_name="Submit",cancel_options={},submit_options={})
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



# Styled form that sits inside of a table, with 
# the left column for the label and the right one for the form elements
# the entire form or individual elements can also be vertical
# in which case labels will appear above form elements (but still inside of 
# a table)
class TabledForm < StyledForm
  include StyledFormBuilderGenerator::Generator
  
  include TabledFormElements

  
  def form_options(tag,field,output,options) #:nodoc:
    label = emit_label(options.delete(:label) || field.to_s.humanize)
    noun = emit_label(options.delete(:noun)) if options[:noun]
    options[:class] = options[:class] ? tag + '_input ' + options[:class] : tag + '_input '
    cols = options.delete(:columns) || 1
    unstyled = options.delete(:unstyled)
    description = emit_label(options.delete(:description))
    output_opts = {
      :field => field,
      :label => label,
      :control => tag,
      :unit => emit_label(options.delete(:unit) || ''),
      :tail => options.delete(:tail),
      :required => options.delete(:required),
      :vertical => options.delete(:vertical) || @frm_options[:vertical],
      :error => ( options.delete(:skip_error) ? nil : output_error_message( noun || label,field) ),
      :valign => options[:valign],
      :description => description.to_s.gsub("\n","<br/>"),
      :cols => cols,
      :unstyled => unstyled
    }
    output_opts[:output] = output.call( :class => options[:class] )
    output_opts
  end
  
  # Output a custom field that will work inside of the form
  def custom_field(field,options={},&block)
    opts = options.clone
    
    label = emit_label(opts.delete(:label) || field.to_s.humanize)
    noun = emit_label(opts.delete(:noun)) if options[:noun]

    error = ''
    if error_message = output_error_message( noun || label,field)
      error = "<tr><td></td><td class='error'>#{error_message}</td></tr>"
    end
    
    cols = (options.delete(:columns) || 1)
    
    valign = options[:valign] || 'baseline'
    
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
      
	error + "<tr><td class='label'  valign='#{valign}' >" + vals[:label] + required + "</td><td valign='baseline' class='data #{options[:control]}_control' colspan='#{cols}'>" + vals[:output] + '</td></tr>' + description.to_s
      end
    else
      vertical = options.delete(:vertical)
      label = options.delete(:label) || field.to_s.humanize
      if vertical
          description = "<tr><td colspan='#{cols+1}' class='description'>#{options[:description]}</td></tr>" if !options[:description].blank?
	@template.concat("<tr><td colspan='#{cols+1}' class='label_vertical'>" + emit_label(label) + required + '</td></tr>' + error + "<tr><td colspan='#{cols+1}' class='data " + options[:control].to_s + "_control'>")
      else
         description = "<tr><td/><td class='description' colspan='#{cols}'>#{options[:description]}</td></tr>" if !options[:description].blank?
         @template.concat(error + "<tr><td  class='label' valign='#{valign}' >" + emit_label(label) + required + "</td><td valign='baseline' class='data' colspan='#{cols}'>")
      end
      yield
      @template.concat("</td></tr>" + description.to_s)
    end
  end

  generate_styled_fields('form_options',
                         (field_helpers + %w(label_field label_option_field country_select collection_select select radio_buttons check_boxes grouped_check_boxes grouped_radio_buttons grouped_select ) - %w(radio_button hidden_field))) do 
                          field(@options)
                          end
                          
  def hidden_field(field,options = {}) # :nodoc:
    super
  end
                         
  generate_form_for('<table class="styled_table">','</table>')
  generate_fields_for('<table class="styled_table">','</table>',:name => 'tabled_fields', :display => true)
  generate_fields_for("","",:name => 'tabled_style_fields')
  
  def field(options) #:nodoc:
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
    label = "<label for='#{object_name}_#{options[:field]}'>#{label}</label>"

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


# Tabled form builder that displays attribute values but doesn't
# actual show any form elements
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
  
  def field(options) #:nodoc:
    return "<tr><td #{"valign='top'" if options[:control] == 'text_area'}>#{options[:label]}: </td><td >#{options[:output]}#{options[:unit]||''}</td></tr>"
  end
  
  def radio_buttons(field,tag_values,options = {}) #:nodoc:
	label_option_field(field,tag_values,options)
  end
  
  def select(field,tag_values,options = {}) #:nodoc:
	label_option_field(field,tag_values,options)
  end

  generate_form_for('<table  class="styled_table">','</table>', :display => true)
  generate_fields_for('<table  class="styled_table">','</table>',:name => 'tabled_display_fields', :display => true)
  
end


# Form builder that displays values as clickable links that
# take you to another form
class LinkEditForm < TabledDisplayForm
  include StyledFormBuilderGenerator::Generator
  
  def form_options(tag,field,output,options) # :nodoc:
  	hsh = super
  	hsh[:output] = "<a href='javascript:void(0);' #{@frm_options[:classname] ? "class='#{@frm_options[:classname]}'" : ''} onclick='#{@frm_options[:onclick]}'>#{hsh[:output]}</a>"
  	hsh
  end
  
  generate_form_for('<table  class="styled_table">','</table>', :display => true)
  generate_fields_for('<table  class="styled_table">','</table>',:name => 'link_edit_fields', :display => true)
  
end


# Form builder that uses tabled form and includes the custom cms form elements
# 
# Usage:
#
#    <%= cms_form_for :model, @model do |f| %>
#    <%= cms_fields_for :model, @model do |f| %>
#    <%= remote_cms_form_for :model, @model, ... do |f| %>
#
# Each of the above will wrap the interior in a table, if you need to
# work inside of an existing cms_form_for, use:
#
#    <%= cms_subfields_for :model, @model do |f| %>
class CmsForm < TabledForm

  include WebivaFormElements
  generate_styled_fields('form_options',
                         %w(add_page_selector access_control filemanager_image filemanager_folder filemanager_file price_classes price_range color_field date_field time_zone_select datetime_field upload_image upload_document unsorted_selector content_selector multi_content_selector image_list end_user_selector autocomplete_field ordered_selection_list ordered_array captcha rating_field)) do 
                          field(@options)
                          end

  generate_form_for('<table class="styled_table">','</table>')
  generate_fields_for('<table class="styled_table">','</table>',:name => 'cms_fields')
  generate_fields_for('','',:name => 'cms_subfields')
  generate_fields_for('<table  class="styled_table">','</table>',:name => 'cms_display_fields', :display => true)


end

# Form builder that does not style any form elements but includes
# all custom cms form elements
# 
# Usage:
#
#    <%= cms_unstyled_form_for :model, @model do |f| %>
#    <%= cms_unstyled_fields_for :model, @model do |f| %>
#    <%= remote_cms_unstyled_form_for :model, @model, ... do |f| %>
#
class CmsUnstyledForm < StyledForm
  include StyledFormBuilderGenerator::Generator
  
  include WebivaFormElements
  include EnhancedFormElements

 
  
  generate_styled_fields('unstyled_form_options',
                          field_helpers + %w(label_field label_option_field country_select collection_select select radio_buttons grouped_check_boxes grouped_radio_buttons grouped_select check_boxes) - %w(check_box radio_button hidden_field) +  %w(access_control filemanager_image filemanager_folder filemanager_file price_classes price_range color_field date_field datetime_field upload_image upload_document unsorted_selector content_selector multi_content_selector image_list end_user_selector autocomplete_field ordered_selection_list ordered_array)) do 
      options[:output]
  end

  def unstyled_form_options(tag,field,output,options) #:nodoc:
    options = options.symbolize_keys
    options[:class] = !options[:class].blank? ? tag.to_s + '_input ' + options[:class].to_s : tag.to_s + '_input'
    {
      :output => output.call( {:class => options[:class], :required => nil, :noun => nil, :label => nil })
    }
  end
  
 def output_error_message(label,field) #:nodoc 
    return nil unless @object && @object.errors
    val = super
    "<div class='fieldErrMessage'>#{val}</div>" if val
  end    

  generate_form_for('','')
  generate_fields_for('','',:name => 'cms_unstyled_fields')
  
end
  




