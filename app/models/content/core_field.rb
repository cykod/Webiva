# Copyright (C) 2009 Pascal Rettig.



class Content::CoreField < Content::FieldHandler

  # Get these into the class as class methods
  class << self;
     include ActionView::Helpers::TextHelper
   end
  

  def self.content_fields_handler_info
    { :name => 'Core Field Types' }
  end
  
  register_dynamic_fields :ip_address => 'Ip Address',
  :email => 'User Email',
  :user_identifier => 'User Identifier',
  :user_id => 'User ID',
  :city => 'City',
  :state => 'State',
  :page_connection => 'Page Connection',
  :current => 'Current Date and Time'
  
# Available Content Fields, with meta information
  register_content_fields [ { :name => :string, 
                         :description => 'Standard Text Field',
                         :representation => :string,
                         :dynamic_fields => [ :ip_address,:email,:user_identifier,:city,:state,:page_connection ]
                       },
                       { :name => :text, 
                         :description => 'Long Text',
                         :representation => :text
                       },                       
                       { :name => :html, 
                         :description => 'HTML Code',
                         :representation => :text
                       },                       
                       { :name => :editor, 
                         :description => 'Wysiwyg Editor',
                         :representation => :text
                       },                       
                       { :name => :email, 
                         :description => 'Email Address',
                         :representation => :string,
                         :dynamic_fields => [ :email  ]
                       },
                       { :name => :image,
                          :description => 'Image',
                          :representation => :integer,
                          :relation => true
                       },
                       { :name => :document,
                          :description => 'Document',
                          :representation => :integer,
                          :relation => true
                       },
                       {  :name => :options,
                          :description => 'Options',
                          :representation => :string,
                          :dynamic_fields => [ :page_connection ]
                       },
                       {
                         :name => :us_state,
                         :description => 'US State Selection',
                         :representation => :string,
                         :dynamic_fields => [:state ]
                       
                       },
                       {  :name => :multi_select,
                          :description => 'Multiple Option Select',
                          :representation => :text
                       },
                       {
                           :name => :boolean,
                           :description => 'Single Checkbox',
                           :representation => :boolean
                       },
                       { :name => :integer, 
                         :description => 'Number (Integer)',
                         :representation => :integer,
                         :dynamic_fields => [ :user_id ]
                       },
                       { :name => :currency, 
                         :description => 'Currency',
                         :representation => :decimal,
                         :migration_options => ":precision=> 14, :scale => 2"
                       },
                       { :name => :date, 
                         :description => 'Date',
                         :representation => :date,
                         :dynamic_fields => [ :current ]
                       },
                       { :name => :datetime, 
                         :description => 'Date And Time',
                         :representation => :datetime,
                         :dynamic_fields => [ :current ]
                       },
                       { :name => :belongs_to, 
                         :description => 'Belongs to Relationship',
                         :representation => :integer,
                         :relation => true,
                         :dynamic_fields => [:user_id ]
                       },
                       { :name => :has_many, 
                         :description => 'Has Many Relationship',
                         :representation => :none,
                         :relation => :plural
                       },
                       { :name => :header, 
                         :description => 'Header',
                         :representation => :none,
                       }       
                     ]  
                     

  
  class StringField < Content::Field
    field_options :required, :unique, :regexp
    setup_model :required, :unique, :regexp
    table_header :string
    
    content_display :text
    filter_setup :like, :empty
    
    def form_field(f,field_name,field_opts,options={})
      field_opts[:class] = 'field_sring_field'
      f.text_field field_name, field_opts.merge(options)
    end
  end
  
  class IntegerField < Content::Field
    field_options :required, :regexp
    setup_model :required, :validates_numericality, :regexp
    table_header :number
    
    content_display :text
    filter_setup :like, :empty
    
    def form_field(f,field_name,field_opts,options={})
      field_opts[:class] = 'field_integer_field'
      f.text_field field_name, field_opts.merge(options)
    end
  end  
  
  # Same as integer, just with a different currency
  class CurrencyField < Content::CoreField::IntegerField

    def form_field(f,field_name,field_opts,options={})
      field_opts[:class] = 'field_currency_field'
      f.text_field field_name, field_opts.merge(options)
    end
    
  end
  
  class TextField < Content::CoreField::StringField
    # Everything the same as StringField except the form field  
    def form_field(f,field_name,field_opts,options={})
      field_opts[:class] = 'field_text_area'
      f.text_area field_name, field_opts.merge(options)
    end
  end
  

  class HtmlField < Content::Field
    field_options :required
    setup_model :required
    table_header :string
    
    content_display :html # Default to non-escaped value
    filter_setup :like, :empty
    
    def form_field(f,field_name,field_opts,options={})
      field_opts[:class] = 'field_text_area'
      f.text_area field_name, field_opts.merge(options)
    end
  end  
  
  class EditorField < Content::CoreField::HtmlField
    # Everything the same as StringField that we want to display an editor area
    def form_field(f,field_name,field_opts,options={})
      field_opts[:class] = 'field_editor_area'
      f.text_area field_name, field_opts.merge(options)
    end
  end  
  
  class EmailField < Content::Field
    field_options :required, :unique
    setup_model :required, :validates_as_email, :unique
    table_header :string
    
    content_display :text
    filter_setup :like, :empty
    
    def form_field(f,field_name,field_opts,options={})
      field_opts[:class] = 'field_email_field'
      f.text_field field_name, field_opts.merge(options)
    end
  end
  
  class UsStateField < Content::Field
    field_options :required
    setup_model :required
    table_header :string
    
    content_display :text
    
    def form_field(f,field_name,field_opts,options={})
      field_opts[:class] = 'field_us_state_field'
      f.select field_name, Content::CoreField::UsStateField.states_select_options
    end
    
    has_options :states,["AL","AK","AR","AS","AZ","CA","CO","CT","DC","DE","FL","FM","GA","GU","HI","IA","ID","IL", "IN","KS","KY","LA","MA","MD","ME","MH","MI","MN","MO","MP","MS","MT","NC","ND","NE","NH","NJ","NM","NV", "NY","OH","OK","OR","PA","PR","PW","RI","SC","SD","TN","TX","UT","VA","VI","VT","WA","WI","WV","WY" ]
    
    filter_setup :like, :empty  
  end
  
  class ImageField < Content::Field
    field_options :required
    table_header :has_relation
    filter_setup :empty
    
    
    setup_model :required do |cls,fld|
      if fld.model_field.field_options['relation_name']
        cls.belongs_to fld.model_field.field_options['relation_name'].to_sym, :class_name => 'DomainFile', :foreign_key => fld.model_field.field
        cls.domain_file_column(fld.model_field.field)
      end
    end
    
    def form_field(f,field_name,field_opts,options={})
      if options[:editor]
        f.filemanager_image field_name, field_opts.merge(options)
      else
        f.upload_image field_name, field_opts.merge(options)
      end    
    end
    
    def content_display(entry,size=:full,options={})
      domain_file = entry.send(@model_field.field_options['relation_name'])
      img_size = options[:size] || (size == :full ? 'original' :  'icon')
      if domain_file
        domain_file.image_tag(img_size,options)
      else
        ''
      end    
    end
    
    def modify_entry_parameters(parameters)
      key = @model_field.field
      if parameters[key.to_s + "_clear"].to_s == '0'
          parameters[key] = nil
      elsif parameters[key].is_a?(String)
        parameters[key] = parameters[key].to_i
      elsif !parameters[key].is_a?(Integer) &&  !parameters[key].blank? 
        image_folder  = Configuration.options.default_image_location || 1
        file = DomainFile.create(:filename => parameters[key],
                                 :parent_id => image_folder)
        if @model_field.field_type == 'document' 
          parameters[key] = file.id
        elsif @model_field.field_type == 'image' && file.file_type == 'img'
         parameters[key] = file.id
        else
          parameters.delete(key)
          file.destroy
        end
      elsif !parameters[key].is_a?(Integer)
         parameters.delete(key)
      end  
      parameters.delete(key.to_s + "_clear")

    end

    
    def assign(entry,values)
      modify_entry_parameters(values)
      entry.send("#{@model_field.field}=",values[@model_field.field]) if values.has_key?(@model_field.field)
    end


    def site_feature_value_tags(c,name_base,size=:full)
      tag_name = @model_field.feature_tag_name
      fld = @model_field
      c.value_tag "#{name_base}:#{tag_name}_url" do |t|
        file = t.locals.entry.send(fld.relation_name)
        if file
          file.url(t.attr['size'] || nil)
        else
          nil
        end
      end

      c.image_tag("#{name_base}:#{tag_name}") { |t| t.locals.entry.send(fld.relation_name) }
    end
  end
  
  class DocumentField < Content::CoreField::ImageField
    # Inherits from ImageField - modify_entry_parameters already checks for field type
    
    def content_display(entry,size=:full,options={})
      h entry.send(@model_field.field_options['relation_name']) ? entry.send(@model_field.field_options['relation_name']).name: ''
    end
    
    def form_field(f,field_name,field_opts,options={})
      if options[:editor]
        f.filemanager_file field_name, field_opts.merge(options)
      else
        f.upload_document field_name, field_opts.merge(options)
      end          
    end


    def site_feature_value_tags(c,name_base,size=:full)
      tag_name = @model_field.feature_tag_name
      fld = @model_field
      
      c.value_tag("#{name_base}:#{tag_name}") do |t|
        df = t.locals.entry.send(fld.relation_name)
        if df
          "<a href='#{df.url}' target='_blank'>#{h(df.name)}</a>"
        else
          nil
        end
      end
      c.value_tag("#{name_base}:#{tag_name}_type") do |t|
        df = t.locals.entry.send(fld.relation_name)
        df ? df.extension : nil
      end
      c.link_tag("#{name_base}:#{tag_name}") do |t|
        df = t.locals.entry.send(fld.relation_name)
        if df
          df.url
        else
          nil
        end
      end
    end
  end

  
    
  
  class OptionsField < Content::Field
    field_options :options, :required
    setup_model :required do |cls,fld|
       cls.has_options fld.model_field.field.to_sym, fld.available_options.clone
    end  
    
    def active_table_header
      ActiveTable::OptionHeader.new(@model_field.field, :label => @model_field.name, :options =>self.available_options)
    end
  
    def available_options
      @available_opts ||= (@model_field.field_options['options'] || []).collect { |fld| fld=fld.to_s.split(";;");[ fld[0].to_s.strip,fld[-1].to_s.strip] }    
    end
    
    
    def form_field(f,field_name,field_opts,options={})
      case options.delete(:control).to_s
      when 'radio'
        field_opts[:class] = 'radio_buttons'
        f.radio_buttons field_name,available_options , field_opts.merge(options)
      when 'radio_vertical'
        field_opts[:class] = 'radio_buttons'
        field_opts[:separator] = '<br/>'
        f.radio_buttons field_name,available_options , field_opts.merge(options)
      else
        f.select field_name, [['--Select--',nil]] + available_options , field_opts.merge(options)
      end    
    end
    
    
    def content_display(entry,size=:full,options={})
      entry.send(@model_field.field + "_display") # From the has_options declared up top
    end

   
    
    filter_setup :like, :empty

    # Let the publication display as radio, vertical radios or a select
    
    display_options_variables :control
    
    def form_display_options(pub_field,f)
       f.radio_buttons :control, [ ['Select Box','select '], ['Radio Buttons','radio' ], ['Vertical Radio Buttons','radio_vertical' ] ]
    end 
  
  end

  class BooleanField < Content::Field
    field_options :on_off_value, :required
    setup_model :required

    def active_table_header
      ActiveTable::BooleanHeader.new(@model_field.field, :label => @model_field.name)
    end

    def form_field(f,field_name,field_opts,options={})
      field_opts[:class] = 'boolean'
      f.check_boxes field_name, [[ @model_field.field_options['on_description'].blank? ? @model_field.field_options['on'] :  @model_field.field_options['on_description'] , true ]],:single => true
    end

    def content_display(entry,size=:full,options={})
      entry.send("#{@model_field.field}?") ? @model_field.field_options['on'] : @model_field.field_options['off']
    end
    
    filter_setup :like, :empty
    
  end
  
  
  class MultiSelectField < Content::Field
    field_options :options, :required
    setup_model :required, :serialize do |cls,fld|
       cls.has_options fld.model_field.field.to_sym, fld.available_options
    end  
    
    def active_table_header
      ActiveTable::OptionHeader.new(@model_field.field, :label => @model_field.name, :options => available_options)
    end    
  
    def available_options
      (@model_field.field_options['options'] || []).collect { |fld| fld=fld.to_s.split(";;");[ fld[0].to_s.strip,fld[-1].to_s.strip] }    
    end
    
    
    def form_field(f,field_name,field_opts,options={})
      field_opts.delete(:size)
      field_opts[:separator] = "<br/>"
      val =  f.object.send(field_name)
      if !val.is_a?(Array)
         f.object.send("#{field_name}=",val.to_s.split("\n"))
      end
      f.check_boxes field_name,  @model_field.content_model.content_model.send(@model_field.field + "_select_options") , field_opts.merge(options)
    end
    
    def content_display(entry,size=:full,options={})
      opts = entry.class.send(@model_field.field + "_options_hash")
      
      val = entry.send(@model_field.field)
      val = [] unless val.is_a?(Array)
      output = []
      val.each { |vl|  output << opts[vl] if opts[vl] }
      separator = options[:separator] || ', '
      h output.join(separator)    
    end
    filter_setup :empty
  end
  
  
  class DateField < Content::Field
    field_options :required
    setup_model :required,:validates_date
    
    filter_setup :empty, :date_range
    
    table_header :date_range
    
    def content_display(entry,size=:full,options = {})
      dt = entry.send(@model_field.field)
      dt ? dt.localize(options[:format] || DEFAULT_DATE_FORMAT) : ''
    end
    
    
    def form_field(f,field_name,field_opts,options={})
      f.date_field field_name, field_opts.merge(options)
    end    
  
  end
  
  class DatetimeField < Content::Field
    field_options :required
    setup_model :required,:validates_datetime
    
    filter_setup :empty, :date_range
    
    table_header :date_range
    
  
    def form_field(f,field_name,field_opts,options={})
      f.datetime_field field_name, field_opts.merge(options)
    end    

    
    def content_display(entry,size=:full,options = {})
      dt = entry.send(@model_field.field)
      dt ? dt.localize(options[:format] || DEFAULT_DATETIME_FORMAT) : ''
    end
    
  
  end
  
  class BelongsToField < Content::Field
    field_options :required, :belongs_to
    setup_model :required  do |cls,fld|
      if fld.model_field.field_options['relation_name'] && fld.model_field.field_options['relation_class']
       cls.belongs_to fld.model_field.field_options['relation_name'].to_sym, :class_name => fld.model_field.field_options['relation_class'], :foreign_key => fld.model_field.field        
      end
    end
    
    table_header :has_relation

    display_options_variables :control, :group_by_id
    
    filter_setup :empty

    
    
    def form_field(f,field_name,field_opts,options={})
      if cls = @model_field.relation_class
        if options[:group_by_id] && mdl_field = ContentModelField.find_by_id(options[:group_by_id])
          all_elems = cls.find(:all)

          available_options =  {}
          all_elems.group_by { |elm| mdl_field.content_display(elm) }.each do |key,arr|
            available_options[key] = arr.map { |elm| [ elm.identifier_name, elm.id ] }
          end
          case options.delete(:control).to_s
          when 'radio'
            field_opts[:class] = 'radio_buttons'
            f.grouped_radio_buttons field_name,available_options , field_opts.merge(options)
          when 'radio_vertical'
            field_opts[:class] = 'radio_buttons'
            field_opts[:separator] = '<br/>'
            f.grouped_radio_buttons field_name,available_options , field_opts.merge(options)
          else
            f.grouped_select field_name, available_options, field_opts.merge(options)
          end
        else
          available_options = cls.select_options
          case options.delete(:control).to_s
          when 'radio'
            field_opts[:class] = 'radio_buttons'
            f.radio_buttons field_name,available_options , field_opts.merge(options)
          when 'radio_vertical'
            field_opts[:class] = 'radio_buttons'
            field_opts[:separator] = '<br/>'
            f.radio_buttons field_name,available_options , field_opts.merge(options)
          else
            f.select field_name, [['--Select %s--' / @model_field.name, nil ]] +  available_options , field_opts.merge(options)
          end
        end
      else
        f.custom_field field_name, options.merge(field_opts.merge(:value => 'Invalid Relation' ))

      end
    end    
    
    def content_display(entry,size=:full,options={})
      if @model_field.field_options['relation_class']
        begin
          h(entry.send(@model_field.field_options['relation_name']) ? entry.send(@model_field.field_options['relation_name']).identifier_name : '')
        rescue
          "Invalid Content Model"
        end
      end
    end
    
    def form_display_options(pub_field,f)
      mdl  =  pub_field.content_model_field.content_model_relation
      if mdl
        f.radio_buttons(:control, [ ['Select Box','select '], ['Radio Buttons','radio' ], ['Vertical Radio Buttons','radio_vertical' ] ]) + 
          f.select(:group_by_id, [["--Don't Group Fields--".t,nil ]] + mdl.content_model_fields.map { |fld| [fld.name, fld.id ]} )
      else
        nil
      end
    end 

    
  end

  class HasManyField < Content::Field
    field_options :required, :has_many

    setup_model  do |cls,fld|
#      cls.validates_presence_of "#{fld.model_field.field_options['relations_singular']}_ids" if fld.model_field.field_options['required']
      if fld.model_field.field_options['relation_name'] && fld.model_field.field_options['relation_class']
        cls.has_through_relations(fld.model_field)
      end
    end

    table_header :static

    display_options_variables :control, :group_by_id, :filter_by_id, :filter, :order_by_id

    def form_field(f,field_name,field_opts,options={})
      if cls = @model_field.relation_class
        if options[:order_by_id] && order_field =  ContentModelField.find_by_id(options[:order_by_id])
          order_by = "`#{order_field.field}`"
        else
          order_by = nil
        end

        filter = field_opts.delete(:filter) || options[:filter]
        if options[:filter_by_id] && (fltr_field =  ContentModelField.find_by_id(options[:filter_by_id])) && !filter.blank?
          conditions = { fltr_field.field => filter }
        else
          conditions = nil
        end
        
        if options[:group_by_id] && mdl_field = ContentModelField.find_by_id(options[:group_by_id])

          all_elems = cls.find(:all,:conditions => conditions, :order => order_by)

          available_options =  {}
          all_elems.group_by { |elm| mdl_field.content_display(elm) }.each do |key,arr|
            available_options[key] = arr.map { |elm| [ elm.identifier_name, elm.id ] }
          end
          available_options = available_options.to_a.sort { |a,b| a[0] <=> b[0] }
          control = :grouped_check_boxes
        else
          available_options = cls.select_options(:conditions => conditions,:order => order_by)

          if !order_by
            available_options.sort! { |a,b| a[0].downcase <=> b[0].downcase }
          end
          
          control = :check_boxes
        end

        
        case options.delete(:control).to_s
        when 'checkbox'
          field_opts[:class] = 'check_boxes'
          f.send(control, "#{@model_field.field_options['relation_singular']}_ids",available_options , field_opts.merge(options))
        else
          field_opts[:class] = 'check_boxes'
          field_opts[:separator] = '<br/>'
          f.send(control,"#{@model_field.field_options['relation_singular']}_ids",available_options , field_opts.merge(options))
        end
      else
        f.custom_field field_name, options.merge(field_opts.merge(:value => 'Invalid Relation' ))
      end
    end    
    
    def content_display(entry,size=:full,options={})
      if !@model_field.field_options['relation_class'].blank?
        begin
          h(entry.send(@model_field.field_options['relation_name']) ? entry.send(@model_field.field_options['relation_name']).map(&:identifier_name).join(", ") : '')
        rescue Exception => e
          "Invalid Content Model"
        end
      end
    end

    def assign_value(entry,value)
      if @model_field.relation_class
        entry.send("#{@model_field.field_options['relation_singular']}_ids=",value)
      end
    end
    
    def assign(entry,values)
      if @model_field.relation_class
        entry.send("#{@model_field.field_options['relation_singular']}_ids=",values["#{@model_field.field_options['relation_singular']}_ids".to_sym ])
      end
    end

    def form_display_options(pub_field,f)
      mdl  =  pub_field.content_model_field.content_model_relation
      if mdl
        f.radio_buttons(:control, [ ['Check Boxes','checkbox '], ['Vertical Check Boxes','vertical_checkbox' ] ]) + 
          f.select(:group_by_id, [["--Don't Group Fields--".t,nil ]] + mdl.content_model_fields.map { |fld| [fld.name, fld.id ]} ) +
          f.select(:filter_by_id, [["--Don't Allow Filtering--".t,nil ]] + mdl.content_model_fields.map { |fld| [fld.name, fld.id ]} ) +
          f.text_field(:filter, :description => "Can be overridden in a site feature by adding a 'filter' attribute to the field") +
            f.select(:order_by_id, [["--Use Default Order--".t,nil ]] + mdl.content_model_fields.map { |fld| [fld.name, fld.id ]} ) 
      else
        nil
      end
    end 
    
  end


  class HeaderField < Content::Field
    field_options
    setup_model 
    table_header :none

    def content_display(entry,size,options={})
      h(@model_field.name)
    end

    def data_field?; false; end

    filter_setup
    
    def form_field(f,field_name,field_opts,options={})
      f.header @model_field.name, field_opts.merge(options)
    end

    def assign_value(entry,value)
      # Can't assign
    end
    
    def assign(entry,values)
      # Can't assign
    end    
  end
  
  def self.dynamic_current_value(entry,fld,state = {})
    Time.now
  end
  

  
  def self.dynamic_ip_address_value(entry,fld,state = {})
    state[:controller].request.remote_ip if state[:controller]
  end
  
  def self.dynamic_email_value(entry,fld,state = {})
    state[:user].email
  end
  
  def self.dynamic_user_identifier_value(entry,fld,state = {})
    if state[:user].id 
      "#{state[:user].email} (#{state[:user].id})"
    else
      "Anonymous"
    end
  end
  
  def self.dynamic_city_value(entry,fld,state = {})
    begin
      MapZipcode.find_by_zip(entry.zipcode).city
    rescue Exception => e
      ''
    end
  end
  
  def self.dynamic_state_value(entry,fld,state ={})
    begin
      MapZipcode.find_by_zip(entry.zipcode).state
    rescue Exception => e
      ''
    end
  end

  def self.dynamic_user_id_value(entry,fld,state={})
    if state[:user]
      state[:user].id
    end
  end
  
  def self.dynamic_page_connection_value(entry,fld,state = {})
    val = state[:page_connection]
    if fld.content_model_field.field_type == 'options' # validate input if it's an option
      fnd = fld.content_model_field.module_class.options
      val = fnd ? val : ''
    end
  end
  
end
