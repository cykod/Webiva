# Copyright (C) 2009 Pascal Rettig.

# Content module Contains all functionality related to the custom content model system
# with the exception of the supporting DomainModel's 
#
# See also: ContentModel, ContentPublication, ContentModelField, ContentPublicationField
# for more classes related to custom content models
module Content


  # Content::Field is the parent class from which all content model field types inherit.
  # See core_field.rb for an example of how to create a Content::FieldHandler.
  #
  # Each Content:FieldHandler defines one or more types of fields, each of which should
  # derive from Content::Field (although this is not required)
  #
  # Content::Field defines a number of method-generating class methods which make it
  # easier to use standard functionality without a lot of boiler plate code.
  # For example the StringField (a common custom content model field type) is defined as:
  #
  #     class StringField < Content::Field # :nodoc:all
  #       field_options :required, :unique, :regexp
  #       setup_model :required, :unique, :regexp
  #       table_header :string
  #      
  #       content_display :text
  #       filter_setup :like, :not_empty
  #      
  #       def form_field(f,field_name,field_opts,options={})
  #         field_opts[:class] = 'field_string_field'
  #         f.text_field field_name, field_opts.merge(options)
  #       end
  #     end
  #
  # It used the field_options, setup_model, table_header, content_display
  # and filter_setup method generators and then defines a custom form_field method
  # used to display the field in a form      
  class Content::Field

    include ModelExtension::OptionsExtension # add has_option functionality

    attr_accessor :model_field

    def initialize(model_field)
      @model_field = model_field
    end
    
    @@field_procs = {
      :required => Proc.new { |field,field_opts,options| field_opts['required'] = options[:required].blank? ? false  : true   },
      :unique => Proc.new { |field,field_opts,options| field_opts['unique'] = options[:unique].blank? ? false  : true   },
      :regexp => Proc.new do |field,field_opts,options|
        field_opts['regexp'] = options[:regexp].blank? ? false  : true  
        field_opts['regexp_code'] = options[:regexp_code]
        field_opts['regexp_message'] = options[:regexp_message]      
      end,
      :on_off_value => Proc.new do |field,field_opts,options|
        field_opts['on'] = options[:on]
        field_opts['off'] = options[:off]
        field_opts['on_description'] = options[:on_description]
      end,
      :options => Proc.new { |field,field_opts,options|  field_opts['options'] = options[:options_text].to_s.strip.split("\n").map(&:strip) },
      :belongs_to => Proc.new { |field,field_opts,options|  
        belongs_class_name = options[:belongs_to]
        if ContentModel.relationship_classes.detect { |cls| cls[1] == belongs_class_name }
          field_opts['relation_class'] = belongs_class_name.camelcase
          field_opts['add_has_many'] = options[:add_has_many].blank? ? false : true
        else
          field_opts['relation_class'] = nil
        end 
      },
      :has_many =>  Proc.new { |field,field_opts,options|  
        belongs_class_name = options[:belongs_to]
        if ContentModel.relationship_classes.detect { |cls| cls[1] == belongs_class_name }
          field_opts['relation_class'] = belongs_class_name.camelcase
        else
          field_opts['relation_class'] = nil
        end 
      },
      :folder_id => Proc.new { |field,field_opts,options|
        field_opts['folder_id'] = options[:folder_id].to_i > 0 ? options[:folder_id].to_i : nil
      }
    }
    
    # Defines which configuration options should be available for this field
    # Note, these only defines the available options, it does not actually set up the model
    # with this upsets see Content::Field#self.setup_model for those generators
    # Available generators are:
    #
    # [:required] 
    #   This this field can be made required 
    # [:unique]
    #   This filed can be made unique across all entires
    # [:reqexp] 
    #   This field can be validated with a regexp
    # [:on_off_value]
    #   This field can have separate on and off values
    # [:options]
    #   This field has a set of user-definable options
    # [:belongs_to]
    #   This field belongs to another content model
    # [:has_many]
    #   This field can have many other content models
    def self.field_options(*options)
      options.each do |opt|
        raise 'Invalid Field Option:' + opt.to_s unless @@field_procs[opt] 
      end
      
      field_options_code =  <<-EOF
      def set_field_options(options)
        returning field_opts = {} do
          field_opts['hidden'] = options['hidden'].blank? ? false : true
          field_opts['exclude'] = options['exclude'].blank? ? false : true
          #{options.map { |opt| "@@field_procs[:#{opt}].call(@model_field,field_opts,options||{})" }.join("\n")}
        end
      end
      EOF
      self.class_eval field_options_code, __FILE__, __LINE__ 
      
      
      define_method(:field_options_partial) { "/content/core_field/core_field_options" }
      define_method(:field_options_widgets) { options } 
    end
    
    @@setup_model_procs = {
      :required => Proc.new { |cls,fld|  cls.validates_presence_of fld.model_field.field if fld.model_field.field_options['required'] },
      :required_array => Proc.new { |cls,fld| cls.validate { |mdl| mdl.errors.add(fld.model_field.field, 'is missing') if fld.model_field.field_options['required'] && mdl.send(fld.model_field.field) && mdl.send(fld.model_field.field).reject(&:blank?).length == 0 } },
      :unique =>  Proc.new { |cls,fld|  cls.validates_uniqueness_of fld.model_field.field, :allow_blank => true if fld.model_field.field_options['unique'] },
      :regexp => Proc.new { |cls,fld| cls.validates_format_of fld.model_field.field, :with => Regexp.new(fld.model_field.field_options['regexp_code']), :message => fld.model_field.field_options['regexp_message'].to_s, :allow_blank => true if fld.model_field.field_options['regexp'] },
      :validates_as_email => Proc.new { |cls,fld| cls.validates_as_email fld.model_field.field },
      :validates_date => Proc.new { |cls,fld| cls.validates_date fld.model_field.field,:allow_nil => true },
      :validates_datetime => Proc.new { |cls,fld| cls.validates_datetime fld.model_field.field,:allow_nil => true },
      :serialize => Proc.new { |cls,fld| cls.serialize fld.model_field.field if cls.respond_to?(:serialize) },
      :validates_numericality => Proc.new { |cls,fld| cls.validates_numericality_of fld.model_field.field, :allow_nil => true },
    }
    
    # Defines which a number of configuration and validatation options that can be set on the model
    #
    # Available Options:
    #
    # [:required]
    #   Adds a validates_presence_of on this field if the configuration option is set
    # [:unique]
    #   Adds a validates_uniquness_of on this field if the configuration option is set
    # [:regexp]
    #   Adds a validates_format_of on this field if the configuration option is set
    # [:validates_as_email]
    #   Adds a validates_as_email
    # [:validates_date]
    #   Adds a validates_date
    # [:validates_datetime]
    #   Adds a validates_datetime
    # [:serialize]
    #   Adds a serialize on this field
    # [:validates_numericality]
    #   Adds a validates numericality of
    def self.setup_model(*options,&block)
      options.each do |opt|
        raise 'Invalid Model Setup Option:' + opt.to_s unless @@setup_model_procs[opt] 
      end
      
      define_method(:setup_model) do |cls|
        options.each do |opt|
          if opt.is_a?(Symbol)
            @@setup_model_procs[opt].call(cls,self)
          elsif opt.is_a?(Proc)
            opt.call(cls,self)
          end
        end
        block.call(cls,self) if block
        setup_hash_model(cls)
      end
    end
    
    def setup_hash_model(cls) #:nodoc:
      return unless cls.superclass == HashModel

      case content_field[:representation]
      when :integer
        cls.integer_options @model_field.field.to_sym
      when :boolean
        cls.boolean_options @model_field.field.to_sym
      end
    end

    # Returns field information hash from register_content_fields
    def content_field
      @content_field ||= ContentModel.content_field(@model_field.field_module,@model_field.field_type)
    end

    @@content_display_methods = {
      :text => "Content::Field.text_value(entry.send(@model_field.field),size,options)",
      :html => "Content::Field.html_value(entry.send(@model_field.field),size,options)",
      :code => "Content::Field.code_value(entry.send(@model_field.field),size,options)"
    }
    
    # Creates a content_display method of a specific type
    # either :text, which escapes any html values
    # or :html, which displays content as is
    def self.content_display(type)
      raise 'Invalid Display Type' unless @@content_display_methods[type]
      content_display_code = <<-EOF
      def content_display(entry,size=:full,options = {})
        #{@@content_display_methods[type] }
      end
      EOF
      self.class_eval content_display_code, __FILE__, __LINE__ 
    end

    # Returns the value of this field, can be overridden manually if necessary
    # (for more complex or fields for exapmle)
    def content_value(entry)
      entry.send(@model_field.field)
    end 

    # Returns the value of this field, can be overridden manually if necessary
    # (for more complex or fields for exapmle)
    def content_export(entry)
      content_value(entry)
    end


    def self.code_value(val,size,options={})
      case size
      when :excerpt, :form
       text_value(val,size,options)
      else
        val
      end
    end

    def self.html_value(val,size,options={})
      case size
      when :excerpt
        text_value( Util::TextFormatter.text_plain_generator(val),size,options)
      else
        val
      end
    end
    
    # Helper method for escaping an html value
    def self.text_value(val,size,options={})
      options.symbolize_keys!
      if size == :excerpt
        content_smart_truncate(val)
      elsif options[:format] && options[:format] == 'html'
        val
      elsif options[:format] && options[:format] == 'simple'
        simple_format(h(val))
      else
        if options[:snippet]
          Content::Field.snippet(h(val),options[:snippet].to_i,options[:omission] || '...')
        else
          h val
        end
      end
    end  

    # Helper method for intelligently truncating text
    def self.snippet(text, wordcount, omission)
      split_text = text.split
      split_text[0..(wordcount-1)].join(" ") + (split_text.length > wordcount ? " " + omission : "")
    end

    
    def self.white_list_sanitizer #:nodoc;
      @@white_list_sanitizer ||= HTML::WhiteListSanitizer.new
    end
    
    class << self; include ActionView::Helpers::TextHelper; include ActionView::Helpers::TagHelper end
    
    # Intelligently truncates text a value with proper sanitization
    def self.content_smart_truncate(val) 
      val = val.to_s
      if(val  && val.length > 30 && !val.include?(' '))
        truncate(h(val),:length => 30)
      else
        truncate(h(val),:length => 60)
      end        
    end
    
    
    @@relative_date_start_options = [ [ 'No Filter', nil ]] + 
      (2..10).to_a.reverse.collect { |yr| 
      [ "#{yr} Years Ago", "years_#{yr}" ]
    } +
      [ ['Start of Previous Year', 'year_ago'],
        ['Start of Year', 'year'] ] + 
      (2..11).to_a.reverse.collect { |mon|
      [ "#{mon} Months Ago", "#{mon}_month_ago" ]
    } +
      [ ['Last Month','1_month_ago'],
        ['Start of Month','0_month' ],
        ['Start of Week', '0_week' ],
        ['Yesterday','1_day_ago'],
        ['Midnight','midnight'],
        ['Now','now'],
        ['Tomorrow','1_day'],
        ['Next Week', '1_week' ],
        ['Next Month', '1_month' ]
      ] +
      (2..11).to_a.collect { |mon|
      [ "In #{mon} Months", "#{mon}_month" ]
    } + [ ['Start of Next Year' , 'next_year' ] ]
    @@relative_date_end_options =  [ ['No Filter', nil ], 
                                     ['One Week from start date','week' ],
                                     ['End of Month from start date','mon'],
                                     ['One Month from start date','1'] ] +
      (2..24).to_a.collect { |mon|
      [ "#{mon} Months from start date", mon.to_s ]
    } +
      (3..12).to_a.collect { |yr|
      [ "#{yr} Years from start date", "years_#{yr}" ]
    } 

    
    def self.relative_date_start_options #:nodoc:
      @@relative_date_start_options
    end
    
    def self.relative_date_end_options #:nodoc:
      @@relative_date_end_options + @@relative_date_start_options[1..-1]
    end    
    
    # Helper method to calculate filter starts dates based on relative options
    def self.calculate_filter_start_date(start_option) 
      start_option ||= ''
      now = Time.now
      if start_option =~ /^([0-9]+)_month_ago$/
        start = now.at_beginning_of_month.months_ago($1.to_i)
      elsif start_option =~ /^([0-9]+)_month$/
        start = now.at_beginning_of_month.months_since($1.to_i)
      elsif start_option =~ /^years_([0-9]+)$/
        start = now.at_beginning_of_year.years_ago($1.to_i)
      else
        case start_option
        when 'now':
            start = now
        when 'year_ago':
            start = now.at_beginning_of_year.years_ago(1)
        when 'year':
            start = now.at_beginning_of_year
        when '0_month':
            start = now.at_beginning_of_month
        when '0_week':
            start = now.at_beginning_of_week
        when '1_week':
            start = now.next_week
        when '1_day':
            start = now.tomorrow
        when 'midnight':
            start = now.at_midnight
        when '1_day_ago':
            start = now.yesterday
        when 'next_year':
            start = now.at_beginning_of_year.next_year
        else
          start = now
        end
      end
      
      start
    end
    
    # Helper method for filters to calculate ending dates
    # based on relatize options
    def self.calculate_filter_end_date(start,end_option) 
      start = start.to_time unless start.is_a?(Time)
      end_option ||= '24'
      if end_option == 'week'
        end_time = start.next_week
      elsif end_option == 'mon'
        end_time = start.at_end_of_month
      elsif end_option =~ /^years_([0-9]+)$/
        end_time = start.years_since($1.to_i)
      elsif end_option =~ /^[0-9]+$/
        end_time = start.months_since(end_option.to_i)
      else 
        end_time = self.calculate_filter_start_date(end_option)
      end
      
      end_time
    end
    
    @@filter_procs = {}


    @@filter_procs[:multiple_like] = { 
      :variables => Proc.new { |field_name,fld| [ (field_name + '_options').to_sym  ]  },
      :options => Proc.new do |field_name,fld,f,attr|
        label_name = fld.model_field.name + " Filter".t
        if attr[:single]
          f.radio_buttons(field_name + "_options",fld.available_options, { :label => label_name}.merge(attr))
        else
          f.check_boxes(field_name + "_options",fld.available_options, { :label => label_name}.merge(attr))
        end
      end,
      :conditions => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_options").to_sym]
        val  = [ val ] unless val.is_a?(Array)
        val = val.reject(&:blank?)
        values = val.map {  |elm| "%\n- #{elm}%"}
        val.length == 0 ? nil :{ :conditions =>  values.map { |elm| "(#{fld.escaped_field} LIKE ?)" }.join(" OR "), :values => values }
      end ,
      :fuzzy =>  Proc.new do |field_name,fld,options|
        val =  options[(field_name + "_options").to_sym]
        val  = [ val ] unless val.is_a?(Array)
        val = val.reject(&:blank?)
        values = val.map {  |elm| "%\n- #{elm}%"}
        val.length == 0 ? nil :{ :score => "IF( " +  values.map { |elm| "(#{fld.escaped_field} LIKE #{DomainModel.quote_value(elm)})" }.join(" OR ") + ",1,0)" }
      end,
      :display => Proc.new do |field_name,fld,options|
        val =  options[(field_name + "_options").to_sym]
        val  = [ val ] unless val.is_a?(Array)
        val = val.reject(&:blank?)
        val.length == 0 ? nil : val.map {  |elm| "\"#{elm}\"" }.join(", ")
        
      end
    }

    @@filter_procs[:not_empty] = {
      :variables => Proc.new { |field_name,fld| [ (field_name + '_not_empty').to_sym  ]  },
      :options => Proc.new do |field_name,fld,f,attr|
        label_name = fld.model_field.name + " Filter".t
        f.check_boxes(field_name + "_not_empty",[ [attr[:label] || 'Not Empty'.t,'value']], :label => label_name, :single => true )    
      end,
      :fuzzy => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_not_empty").to_sym]
        val.blank? ? nil : {:score =>  "IF(#{fld.escaped_field} != '',1,0) " }
      end,
      :conditions => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_not_empty").to_sym]
        val.blank? ? nil : {:conditions =>  "#{fld.escaped_field} != ''" }
      end,
      :display => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_not_empty").to_sym]
        val.blank? ? nil : 'No Empty'
      end
    }


   @@filter_procs[:empty] = {
      :variables => Proc.new { |field_name,fld| [ (field_name + '_empty').to_sym  ]  },
      :options => Proc.new do |field_name,fld,f,attr|
        label_name = fld.model_field.name + " Filter".t
        f.check_boxes(field_name + "_empty",[ [attr[:label] || 'Empty'.t,'value']], :label => label_name, :single => true )    
      end,
      :fuzzy => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_empty").to_sym]
        val.blank? ? nil : {:score =>  "IF(#{fld.escaped_field} = '' OR #{fld.escaped_field} IS NULL,1,0) " }
      end,
      :conditions => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_empty").to_sym]
        val.blank? ? nil : {:conditions =>  "(#{fld.escaped_field} = '' OR #{fld.escaped_field} IS NULL)" }
      end,
      :display => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_empty").to_sym]
        val.blank? ? nil : 'Empty'
      end
    }

    @@filter_procs[:like] = {
      :variables => Proc.new { |field_name,fld| [ (field_name + '_like').to_sym  ]  },
      :options => Proc.new do |field_name,fld,f,attr|
        label_name = fld.model_field.name + " Filter".t
        f.text_field(field_name + "_like", {:size => 40, :label => label_name})
      end,
      :fuzzy => Proc.new do |field_name,fld,options|
        val =  options[(field_name + "_like").to_sym].to_s.strip
        val.empty? ? nil : { :score =>  "IF(#{fld.escaped_field} LIKE " + DomainModel.quote_value("%" + val + "%") + ",1,0)" }
      end,
      :conditions => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_like").to_sym].to_s.strip
        val.empty? ? nil : { :conditions =>  "#{fld.escaped_field} LIKE ?", :values=> '%' + val + '%' }
      end,
      :display => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_like").to_sym].to_s.strip
        val.empty? ? nil :  "\"#{val}\"" 
      end
    }


    @@filter_procs[:between] = {
      :variables => Proc.new { |field_name,fld| [ (field_name + '_between_less').to_sym, (field_name + '_between_greater').to_sym  ]  },
      :options => Proc.new do |field_name,fld,f,attr|
        less_label_name = fld.model_field.name + " Less Than".t
        greater_label_name = fld.model_field.name + " Greater Than".t
        f.text_field(field_name + "_between_less", {:size => 40, :label => less_label_name}) +
        f.text_field(field_name + "_between_greater", {:size => 40, :label => greater_label_name}) 
      end,
      :fuzzy => Proc.new do |field_name,fld,options|
        less_val =  options[(field_name + "_between_less").to_sym]
        greater_val =options[(field_name + "_between_greater").to_sym]

        if less_val.present? && greater_val.present?
          { :score => "IF(#{fld.escaped_field} < #{DomainModel.quote_value(less_val)} AND #{fld.escaped_field} > #{DomainModel.quote_value(greater_val)},1,0) " }
        elsif less_val.present?
          { :score => "IF(#{fld.escaped_field} < #{DomainModel.quote_value(less_val)},1,0)" }
        elsif greater_val.present?
          { :score => "IF(#{fld.escaped_field} > #{DomainModel.quote_value(greater_val)},1,0)" }
        else 
          nil
        end
      end,
      :conditions => Proc.new do |field_name,fld,options|
        less_val =  options[(field_name + "_between_less").to_sym]
        greater_val =options[(field_name + "_between_greater").to_sym]

        if less_val.present? && greater_val.present?
          { :conditions => "#{fld.escaped_field} BETWEEN ? AND ?", :values => [ greater_val,less_val ] }
        elsif less_val.present?
          { :conditions => "#{fld.escaped_field} <  ?", :values => less_val }
        elsif greater_val.present?
          { :conditions => "#{fld.escaped_field} > ?", :values => greater_val }
        else 
          nil
        end
      end,
      :display => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_between_less").to_sym].to_s.strip
        val = val.empty? ? nil :  "Less than \"#{val}\"" 


      end
    }


    @@filter_procs[:equal] = {
      :variables => Proc.new { |field_name,fld| [ (field_name + '_equal').to_sym  ]  },
      :options => Proc.new do |field_name,fld,f,attr|
        label_name = fld.model_field.name + " Filter".t
        f.text_field(field_name + "_equal", {:size => 40, :label => label_name})
      end,
      :conditions => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_equal").to_sym].to_s.strip
        val.empty? ? nil :{ :conditions =>  "#{fld.escaped_field} = ?", :values => val }
      end ,
      :fuzzy =>  Proc.new do |field_name,fld,options|
        val =  options[(field_name + "_equal").to_sym].to_s.strip
        val.empty? ? nil :  { :score =>  "IF(#{fld.escaped_field} = " + DomainModel.quote_value(val) + ",1,0)" }
      end,
      :display => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_equal").to_sym].to_s.strip
        val.empty? ? nil :  "\"#{val}\"" 
      end
    }

    @@filter_procs[:include] = {
      :variables => Proc.new { |field_name,fld|  [ (field_name + '_include').to_sym  ]  },
      :options => Proc.new do |field_name,fld,f,attr|
        label_name = fld.model_field.name + " Filter".t
        if attr && attr[:control] == 'selects'
          attr[:number]||=3
        end
        fld.form_field(f,field_name + "_include",{},attr)
      end,
      :conditions => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_include").to_sym]
        if val && val.is_a?(Array)
          val = val.reject(&:blank?).map(&:to_i)
          if val.length > 0
            join = "`#{fld.model_field.field}`"
            { :joins =>  "INNER JOIN content_relations as #{join} ON (#{join}.content_model_id = #{fld.model_field.content_model_id} AND #{join}.content_model_field_id = #{fld.model_field.id} AND #{join}.entry_id = `#{fld.model_field.content_model.table_name}`.id)",
              :conditions => "#{join}.relation_id IN (?)",
              :values => [ val ]
            }
          else
            nil
          end
        else
          nil
        end
      end,
      :fuzzy => Proc.new  do |field_name,fld,options|
        val = options[(field_name + "_include").to_sym]
        if val && val.is_a?(Array) && val.length > 0
          val = val.reject(&:blank?).map(&:to_i)
          join = "`#{fld.model_field.field}`"
          if val.length > 0
            { :joins =>  "LEFT JOIN content_relations as #{join} ON (#{join}.content_model_id = #{fld.model_field.content_model_id} AND #{join}.content_model_field_id = #{fld.model_field.id} AND  #{join}.entry_id = `#{fld.model_field.content_model.table_name}`.id AND #{join}.relation_id IN (" + val.map { |v| DomainModel.quote_value(v) }.join(",") + "))",
              :score => "COUNT(DISTINCT #{join}.id)",
              :count => "#{join}.id IS NOT NULL"
            }
          else
            nil
          end
        else
          nil
        end
      end,
      :display => Proc.new  do |field_name,fld,options|
        val = options[(field_name + "_include").to_sym]
        if val && val.is_a?(Array) && val.length > 0
          val = val.reject(&:blank?).map(&:to_i)
          if val.length > 0
            cls = fld.model_field.relation_class
            if cls
              cls.find(:all,:conditions => {  :id => val}).map(&:identifier_name).join(", ")
            else
              nil
            end
          else
            nil
          end
        else
          nil
        end
      end


    }

    @@filter_procs[:options] = {
      :variables => Proc.new { |field_name,fld| [ (field_name + '_options').to_sym  ]  },
      :options => Proc.new do |field_name,fld,f,attr|
        label_name = fld.model_field.name + " Filter".t
        option_attr = { :labels => attr.delete(:labels), :limit => attr.delete(:limit), :offset => attr.delete(:offset) }
        if attr.delete(:select)
          f.select(field_name + "_options",[[attr.delete(:blank) || '--Select--'.t,nil]] + fld.available_options(option_attr), { :label => label_name}.merge(attr))
        elsif attr.delete(:single)
          f.radio_buttons(field_name + "_options",fld.available_options(option_attr), { :label => label_name}.merge(attr))
        else
          f.check_boxes(field_name + "_options",fld.available_options(option_attr), { :label => label_name}.merge(attr))
        end
      end,
      :conditions => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_options").to_sym] if options[(field_name + "_options").to_sym] != [""]

        # Handle cases where we get the object id or target sent in (mostly for belongs_to)
        val = options[(field_name + "_id").to_sym] if val.blank?
        val = options[field_name.to_sym] if val.blank?
        if val && val.kind_of?(DomainModel)
          val = val.id ? val.id : 0
        end

        val  = [ val ] unless val.is_a?(Array)
        val = val.reject(&:blank?)
        val.length == 0 ? nil :{ :conditions =>  "#{fld.escaped_field} IN (?)", :values => [ val ] }
      end ,
      :fuzzy =>  Proc.new do |field_name,fld,options|
        val = options[(field_name + "_options").to_sym] if options[(field_name + "_options").to_sym] != [""]

        # Handle cases where we get the object id or target sent in (mostly for belongs_to)
        val = options[(field_name + "_id").to_sym] if val.blank?
        val = options[field_name.to_sym] if val.blank?
        if val && val.kind_of?(DomainModel)
          val = val.id ? val.id : 0
        end

        val  = [ val ] unless val.is_a?(Array)
        val = val.reject(&:blank?)
        val.length == 0 ? nil : { :score =>  "IF(#{fld.escaped_field} IN (" + val.map { |elm| DomainModel.quote_value(elm) }.join(",") + "),1,0)" }
      end,
      :display => Proc.new do |field_name,fld,options|
        val = options[(field_name + "_options").to_sym]
        val  = [ val ] unless val.is_a?(Array)
        val = val.reject(&:blank?)
        val.length == 0 ? nil : fld.available_options.map {  |opt| val.include?(opt[1]) ? opt[0] : nil  }.compact.join(", ")
      end

    }

    @@filter_procs[:date_range] = {
      :variables => Proc.new { |field_name,fld| [ (field_name + '_start').to_sym, (field_name + '_end').to_sym  ]  },
      :options => Proc.new do |field_name,fld,f,attr|
        label_name = fld.model_field.name + " Filter".t
        f.select(field_name + "_start", 
                 Content::Field.relative_date_start_options, 
                 :label => (label_name + " Start".t)) +
          f.select(field_name + "_end", 
                   Content::Field.relative_date_end_options, 
                   :label => (label_name + " End".t))          
      end,
      :conditions => Proc.new do |field_name,fld,options|
        start_val = options[(field_name + "_start").to_sym].to_s
        end_val = options[(field_name + "_end").to_sym].to_s
        
        conditions = []
        values = []
        
        start_date = Time.now
        if !start_val.empty?
          
          start_date =Content::Field.calculate_filter_start_date(start_val)
          conditions << "#{fld.escaped_field} >= ?"
          values << (fld.model_field.field_type == 'date' ? start_date.to_date : start_date)
        end
        
        if !end_val.empty?
          end_date =  Content::Field.calculate_filter_end_date(start_date,end_val)
          
          
          conditions << "#{fld.escaped_field} <= ?"
          values << (fld.model_field.field_type == 'date' ? end_date.to_date : end_date)
        end
        conditions.length > 0 ? { :conditions => conditions.join(" AND "), :values => values } : nil

      end                
    }   

    def filter_variables; []; end
    
    
    # Sets up filter methods compatible with this field. 
    #
    # Available options are:
    # [:multiple_like]
    # Mysql like query on each token of the filter string
    # [:not_empty] 
    #   Allows displays of only the entries that are not empty
    # [:like]
    #   Single like search on the entire filter value
    # [:equal]
    #   Straight equality search on the field
    # [:include]
    #   Will perform a join on the content_relations table for any contained entries
    # [:options]
    #   Will use IN (?) to search for available options
    # [:date_range]
    #   Allows searching on a range of dates
    def self.filter_setup(*options)
      define_method(:filter_options) do |f,name,attr|
        field_name = "filter_" + self.model_field.feature_tag_name

        options.map do |opt|
          if opt.is_a?(Hash) && (name.blank? || opt[:name] == name)
            opt[:options].call(field_name,self,f,attr).to_s
          elsif name.blank? || opt == name.to_sym
            @@filter_procs[opt][:options].call(field_name,self,f,attr).to_s
          else
            ''
          end
        end.join
      end

      define_method(:filter_display) do |filter|
        field_name = "filter_" + self.model_field.feature_tag_name

        display = options.map do |opt|
          if opt.is_a?(Hash) 
            opt[:display].call(field_name,self,filter).to_s
          else
            @@filter_procs[opt][:display].call(field_name,self,filter).to_s
          end
        end.reject(&:blank?).join(", ")
        display.blank? ? nil : display
      end

      define_method(:filter_names) do
        options.map do |opt|
          if opt.is_a?(Hash)
            opt[:name]
          else
            opt.to_sym
          end
        end.compact
      end
      
      define_method(:filter_variables) do
        field_name = "filter_" + self.model_field.feature_tag_name
        options.inject([]) do |lst,opt|
          if opt.is_a?(Hash)
            vars = opt[:variables].call(field_name,self)
          else
            vars = @@filter_procs[opt][:variables].call(field_name,self)
          end
          vars ? lst + vars : lst
        end
      end

      define_method(:filter_conditions) do |field_opts,filter_opts|
        opts = {}
        field_name = "filter_" + self.model_field.feature_tag_name
        options.each do |opt|
          if opt.is_a?(Hash)
            opt_conditions = opt[:conditions].call(field_name,self,field_opts)
          else
            opt_conditions = @@filter_procs[opt][:conditions].call(field_name,self,field_opts)
          end

          if opt_conditions
            opt_conditions.each do |key,val|
              if val
                opts[key] ||= []
                if val.is_a?(Array)
                  opts[key] += val
                else
                  opts[key] << val
                end
              end
            end
          end
        end

        opts
      end

      
      define_method(:fuzzy_filter_conditions) do |field_opts,filter_opts|
        opts = {}
        field_name = "filter_" + self.model_field.feature_tag_name
        options.each do |opt|
          if opt.is_a?(Hash)
            opt_conditions = opt[:fuzzy].call(field_name,self,field_opts)
          else
            opt_conditions = @@filter_procs[opt][:fuzzy].call(field_name,self,field_opts)
          end

          if opt_conditions
            opt_conditions.each do |key,val|
              if val
                opts[key] ||= []
                if val.is_a?(Array)
                  opts[key] += val
                else
                  opts[key] << val
                end
              end
            end

            filter_weight = (filter_opts[:filter_weight]||1.0).to_f

            if opts[:score]
              score = opts.delete(:score).map! { |elm| "(#{elm} * #{filter_weight})" }
              count = opts.delete(:count)

              opts["score_#{filter_opts[:fuzzy_filter]}".to_sym] = score
              opts["count_#{filter_opts[:fuzzy_filter]}".to_sym] = count
            end
          end
        end

        opts
      end    
    end

    # By default this field holds data
    # But some sub-classes may not (e.g. HeaderField)
    # They should override this method and return false
    def data_field?
      true
    end

    # return the escaped field name suitible for 
    # putting in a query
    def escaped_field; @model_field.escaped_field; end
    
    
    def display_options(pub_field,f)#:nodoc:
      ''; end
    def form_display_options(pub_field,f)#:nodoc:
      ''; end
    def filter_display_options(pub_field,f) #:nodoc:
      ; ''; end
    
    
    def display_options_variables #:nodoc:
      []; end
    
    def self.display_options_variables(*opts) #:nodoc:
      define_method(:display_options_variables) { opts }
    end  

    # Returns the header that should be used in creating an active table
    # defaults to a static header, can be overridden manually or by using
    # the table_header method-generator method
    def active_table_header
      ActiveTable::StaticHeader.new(@model_field.field, :label => @model_field.name)  
    end
    
    # Creates the active_table_header method with a [header_type]Header 
    # see ActiveTable for available options
    def self.table_header(header_type)
      if header_type != :none
        header_class = "#{header_type}_header".classify
        header_code =  <<-EOF
      def active_table_header
        ActiveTable::#{header_class}.new("`" + @model_field.field + "`", :label => @model_field.name)  
      end
      EOF
      self.class_eval header_code, __FILE__, __LINE__
    else
      define_method(:active_table_header) { nil } 
    end
  end  
  
  # This can be overridden if any incoming parameters need to be modified
  # before validation
  # (for example from a document field type)
  def modify_entry_parameters(parameters)
    # Dummy, don't do anything
  end


  # Return a options model for the field. Shouldn't be overriden
  # if the field is using the field_options or setup_model method generators
  def field_options_model
    @field_options_model ||= FieldOptions.new(@model_field.field_options)
    #    @field_options_model.set_required_options
  end

  # Create any fields tags for this field in the passed context
  def site_feature_value_tags(c,name_base,size=:full,options={})
    local = options[:local] 
    tag_name = @model_field.feature_tag_name
    fld = @model_field
    c.value_tag "#{name_base}:#{tag_name}" do |t|
      val = fld.content_display(t.locals.send(local),size,t.attr)
      if val.blank?
        nil
      else
        val
      end
    end
    c.value_tag "#{name_base}:#{tag_name}_value" do |t|
      t.locals.send(local).send(fld.field)
    end
  end
  
  # Will assign a single value to this field (used by dynamic fields)
  # can be overriden for any custom functionality
  def assign_value(entry,value)
    entry.send("#{@model_field.field}=",value)
  end
  
  # Assign a value to this entry given a parameters hash
  # can be overriden for custom functionality
  def assign(entry,values)
    entry.send("#{@model_field.field}=",values[@model_field.field.to_sym]) if values.has_key?(@model_field.field.to_sym)
  end

  # Imports a value into the entry, uses assign_value by default
  # but can be overridden for more complex behavior
  def content_import(entry,value)
    assign_value(entry,value)
  end

  def default_field_name #:nodoc:
    @model_field.field
  end
  
  class FieldOptions < HashModel #:nodoc:all
    attributes :required => false, :options => [], :relation_class => nil, :unique => false, :regexp => false, :regexp_code => '', :regexp_message => 'is not formatted correctly', :on => '', :off => '', :on_description => '', :hidden => false, :exclude => false, :relation_name => nil, :relation_singular => nil, :folder_id => nil, :add_has_many => false, :foreign_key => nil
    
    boolean_options :required, :unique, :regexp, :hidden, :exclude, :add_has_many

    def validate
      if !self.regexp_code.blank?
        begin
          Regexp.new(regexp_code)
        rescue Exception => e
          self.errors.add(:regexp,'is not a valid regular expression')
        end
      end
    end
    
    def options_text
      self.options.join("\n");
    end
    
    def options_text=(val)
      self.options = val.to_s.strip.split("\n").map(&:strip)
    end

    def belongs_to
      self.relation_class.to_s.underscore
    end
  end
  
  

end
end
