# Copyright (C) 2009 Pascal Rettig.



class Content::PublicationType


  attr_accessor :publication

  def initialize(pub)
    @publication = pub
  end
  
  def options(val=nil)
    self.options_class.new(val || @publication.data)
  end
  
  def self.options_class(cls)
    define_method(:options_class) { cls }
  end
  
  def self.options_partial(tpl)p
    define_method(:options_partial) { tpl }
  end
  
  def self.field_types(*options)
    if options.last.is_a?(Hash)
      custom_opts = options.pop
      options.concat(custom_opts.to_a)
    end
    
    define_method(:field_types) { options }
  end

  def self.feature_name(name)
    define_method(:feature_method_name) { name }
  end
  
  @@field_types = {
    :entry_value => ['Entry Value','value'],
    :formatted_value => [ 'Formatted Value','format'],
    :input_field => ['Input Field' ,'input'],
    :preset_value => ['Preset Value','preset'],
    :dynamic_value => ['Dynamic Value','dynamic']
  }
  
  def field_type_options
    # Field types is a list of symbols, or an array with a custom type and it's partial
    self.field_types.map do |elm|
      if elm.is_a?(Symbol)
        @@field_types[elm]
      else
        [ elm[0].to_s.humanize, elm[0].to_s ]
      end
    end  
  end
  
  def custom_field_types
    self.field_types.select { |elm|  !elm.is_a?(Symbol) }
  end 
  
  
  def field_options_class
    Content::PublicationFieldOptions
  end
  
  def self.field_options_class(cls)
     define_method(:field_options_class) { cls }
  end
  
  @@field_option_procs = {
    :detail_link => Proc.new() { |type,fld,f| f.check_boxes :options, [['Detail Link','link']], :single => true, :label => '' },
    :filter => Proc.new() do |type,fld,f|
      if(fld.filter_variables.length > 0)
        f.header('Filtering',:description => "Turning on filtering will allow publication paragraphs to show a subset of the entries in this content model.\nWhat entries are displayed can be controlled by an editor in the publication paragraph options,\nor by the user if this filter is 'exposed'") + 
          f.radio_buttons(:filter, [[ 'No Filter',nil], ['Filter','filter'],['Fuzzy Filter','fuzzy']],
                          :description => "Fuzzy filter will generate a weight 'score' for the result and order results by that score"
                         ) +
                           f.radio_buttons(:fuzzy_filter,[ ["Filter A","a"],["Filter B","b"],["Filter C","c"]],:description => "Adding different fields to the same filter will allow entries to show in the results on a partial match,\nwhile using multiple filters will require a match on each filter to appear in the results") + 
                           f.text_field(:filter_weight,:size => 4, :label => 'Fuzzy Filter Weight') +
                           f.check_boxes(:filter_options, [['Expose this filter to users','expose'],['Make filter available as input in page connections','connection']] )
      end
    end,
    :order => Proc.new() do |type,fld,f|
      if fld.data_field? && fld.relation_class_name.blank?
        f.header('Ordering', :description => 'Fields higher in the publication will have a higher ordering priority') +
          f.radio_buttons(:order, [ [ 'None'.t, nil ], ['Ascending'.t, 'asc' ], ['Descending'.t, 'desc' ] ]  ) 
      end
    end
  }
  
  def field_options(fld,f); ''; end 
  
  
  def self.field_options(*options,&block)
    options.each do |opt|
      raise 'Invalid Field Option:' + opt.to_s unless @@field_option_procs[opt] 
    end
  
    define_method(:field_options) do |fld,f|
      output = options.map do |opt|
        if opt.is_a?(Symbol)
          @@field_option_procs[opt].call(self,fld,f)
        elsif opt.is_a?(Proc)
          opt.call(self,fld,f)
        end
      end.join
      output << block.call(self,fld,f) if block
      output
    end
  end

  @@trigger_types = {
    :view =>  ['Publication Viewed','view'],
    :create => [ 'New Entry Created', 'create' ],
    :edit => [ 'Entry Updated', 'edit' ],
    :delete => [ 'Entry Deleted', 'delete' ]
  }
  

 def self.register_triggers(*trigger_list)
   trigger_list.map! do |trigger|
      if trigger.is_a?(Symbol)
        @@trigger_types[trigger]
      else
        trigger
      end
    end
    define_method(:triggers) { trigger_list }
  end
  
  def content_publication_fields
    @publication.content_publication_fields
  end

  def filter?; false; end
  
  def preview_data
    raise 'Override me'
  end
  
end
