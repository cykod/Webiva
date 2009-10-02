# Copyright (C) 2009 Pascal Rettig.



class Content::Field

  include ModelExtension::OptionsExtension # add has_option functionality

  attr_accessor :model_field

  def initialize(model_field)
    @model_field = model_field
  end
  
  @@field_procs = {
      :required => Proc.new { |field,field_opts,options| field_opts['required'] = options[:required].blank? ? false  : true   },
      :options => Proc.new { |field,field_opts,options|  field_opts['options'] = options[:options_text].to_s.strip.split("\n").map(&:strip) },
      :belongs_to => Proc.new { |field,field_opts,options|  
            belongs_class_name = options[:belongs_to]
            if ContentModel.relationship_classes.detect { |cls| cls[1] == belongs_class_name }
              field_opts['relation_class'] = belongs_class_name.camelcase
            else
              field_opts['relation_class'] = nil
            end 
      }
  }
      
  def self.field_options(*options)
    options.each do |opt|
      raise 'Invalid Field Option:' + opt.to_s unless @@field_procs[opt] 
    end
    
    field_options_code =  <<-EOF
      def set_field_options(options)
        returning field_opts = {} do
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
    :validates_as_email => Proc.new { |cls,fld| cls.validates_as_email fld.model_field.field },
    :validates_date => Proc.new { |cls,fld| cls.validates_date fld.model_field.field,:allow_nil => true },
    :validates_datetime => Proc.new { |cls,fld| cls.validates_datetime fld.model_field.field,:allow_nil => true },
    :serialize => Proc.new { |cls,fld| cls.serialize fld.model_field.field },
    :validates_numericality => Proc.new { |cls,fld| cls.validates_numericality_of fld.model_field.field, :allow_nil => true },
  }
  
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
    end
  end
  
  
  @@content_display_methods = {
    :text => "Content::Field.text_value(entry.send(@model_field.field),size,options)",
    :html => "entry.send(@model_field.field)"
  }
  
  def self.content_display(type)
    raise 'Invalid Display Type' unless @@content_display_methods[type]
    content_display_code = <<-EOF
      def content_display(entry,size=:full,options = {})
        #{@@content_display_methods[type] }
      end
    EOF
    self.class_eval content_display_code, __FILE__, __LINE__ 
  end
  
  def self.text_value(val,size,options={})
    if size == :excerpt
      content_smart_truncate(val)
    elsif options[:format] && options[:format] == 'html'
      val
    else
      h val
    end
  end  
  

  def self.white_list_sanitizer
    @@white_list_sanitizer ||= HTML::WhiteListSanitizer.new
  end
  
  class << self; include ActionView::Helpers::TextHelper; end
  
  def self.content_smart_truncate(val)
      val = val.to_s
      if(val  && val.length > 30 && !val.include?(' '))
        white_list_sanitizer.sanitize( truncate(val,:length => 30))
      else
        white_list_sanitizer.sanitize( truncate(val,:length => 60))
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

  
  def self.relative_date_start_options
    @@relative_date_start_options
  end
  
  def self.relative_date_end_options
    @@relative_date_end_options + @@relative_date_start_options[1..-1]
  end    
    
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
 
  @@filter_procs = {
    :empty => {
              :variables => Proc.new { |field_name,fld| [ (field_name + '_not_empty').to_sym  ]  },
              :options => Proc.new do |field_name,fld,f|
                 label_name = fld.model_field.name + " Filter".t
                 f.check_boxes(field_name + "_not_empty",[ ['Not Empty'.t,'value']], :label => label_name, :single => true )    
              end,
              :conditions => Proc.new do |field_name,fld,options|
                val = options[(field_name + "_not_empty").to_sym]
                if !val
                  nil
                else
                  val.blank? ? nil : [ "#{fld.model_field.field} != ''" ]
                end
              end
              },
    :like => {
             :variables => Proc.new { |field_name,fld| [ (field_name + '_like').to_sym  ]  },
             :options => Proc.new do |field_name,fld,f|
                 label_name = fld.model_field.name + " Filter".t
                 f.text_field(field_name + "_like", {:size => 40, :label => label_name})
              end,
              :conditions => Proc.new do |field_name,fld,options|
                val = options[(field_name + "_like").to_sym].to_s.strip
                val.empty? ? nil :[ "`#{fld.model_field.field}` LIKE ?", '%' + val + '%' ]
              end              
              },
    :equal => {
             :variables => Proc.new { |field_name,fld| [ (field_name + '_equal').to_sym  ]  },
             :options => Proc.new do |field_name,fld,f|
                 label_name = fld.model_field.name + " Filter".t
                 f.text_field(field_name + "_equal", {:size => 40, :label => label_name})
              end,
              :conditions => Proc.new do |field_name,fld,options|
                val = options[(field_name + "_equal").to_sym].to_s.strip
                val.empty? ? nil :[ "`#{fld.model_field.field}` = ?", val ]
              end                
              },
    :date_range => {
       :variables => Proc.new { |field_name,fld| [ (field_name + '_start').to_sym, (field_name + '_end').to_sym  ]  },
       :options => Proc.new do |field_name,fld,f|
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
	           conditions << "`#{fld.model_field.field}` >= ?"
	           values << (fld.model_field.field_type == 'date' ? start_date.to_date : start_date)
	        end
	        
	        if !end_val.empty?
	           end_date =  Content::Field.calculate_filter_end_date(start_date,end_val)
	           
	           
	           conditions << "`#{fld.model_field.field}` <= ?"
	           values << (fld.model_field.field_type == 'date' ? end_date.to_date : end_date)
	        end
	        
	        conditions.length > 0 ? [ conditions.join(" AND "), values ] : nil
	        
        end                
    }    
  
  }
  
  def self.filter_setup(*options)
    define_method(:filter_options) do |f|
      field_name = "filter_" + self.model_field.field
      options.map do |opt|
        if opt.is_a?(Hash)
          opt[:options].call(field_name,self,f).to_s
        else
          @@filter_procs[opt][:options].call(field_name,self,f).to_s
        end
      end.join("\n")
    end
    
    define_method(:filter_variables) do
      field_name = "filter_" + self.model_field.field
      options.inject([]) do |lst,opt|
        if opt.is_a?(Hash)
          vars = opt[:variables].call(field_name,self)
        else
          vars = @@filter_procs[opt][:variables].call(field_name,self)
        end
        vars ? lst + vars : lst
      end
    end
    
    define_method(:filter_conditions) do |field_opts|
      conditions = []
      values = []
      field_name = "filter_" + self.model_field.field
      options.each do |opt|
        if opt.is_a?(Hash)
          opt_conditions, opt_values = opt[:conditions].call(field_name,self,field_opts)
        else
          opt_conditions, opt_values = @@filter_procs[opt][:conditions].call(field_name,self,field_opts)
        end
        
        opt_values = [ opt_values ] if !opt_values.blank? && !opt_values.is_a?(Array)
        
        conditions << opt_conditions if opt_conditions
        values += opt_values if opt_values
      end
      
      if conditions.length > 0
        [ conditions.map { |cond| "(#{cond})" }.join(" AND "),  values ]
      else
        []
      end
    
    end
  end
  
  def display_options(pub_field,f); ''; end
  def form_display_options(pub_field,f); ''; end
  
  def display_options_variables; []; end
  
  def self.display_options_variables(*opts)
    define_method(:display_options_variables) { opts }
  end  

  # Default to a static header
  def active_table_header
    ActiveTable::StaticHeader.new(@model_field.field, :label => @model_field.name)  
  end
  
  def self.table_header(header_type)
    header_class = "#{header_type}_header".classify
    header_code =  <<-EOF
      def active_table_header
        ActiveTable::#{header_class}.new(@model_field.field, :label => @model_field.name)  
      end
    EOF
    self.class_eval header_code, __FILE__, __LINE__ 
  end  
  
  def modify_entry_parameters(parameters)
    # Dummy, don't do anything
  end
  
  def field_options_model
    @field_options_model ||= FieldOptions.new(@model_field.field_options)
#    @field_options_model.set_required_options
  end
  
  class FieldOptions < HashModel
    attributes :required => false, :options => []
    
    boolean_options :required
    
    def options_text
      self.options.join("\n");
    end
    
    def options_text=(val)
      self.options = val.to_s.strip.split("\n").map(&:strip)
    end
  end
  
  
  def assign_value(entry,value)
    entry.send("#{@model_field.field}=",value)
  end
  
  def assign(entry,values)
    entry.send("#{@model_field.field}=",values[@model_field.field.to_sym])  
  end
end
