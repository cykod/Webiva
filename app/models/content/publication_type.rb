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
  
  def self.options_partial(tpl)
    define_method(:options_partial) { tpl }
  end
  
  def self.field_types(*options)
    if options.last.is_a?(Hash)
      custom_opts = options.pop
      options.concat(custom_opts.to_a)
    end
    
    define_method(:field_types) { options }
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
    :filter => Proc.new() { |type,fld,f| f.check_boxes :options, [[ 'Filter','filter']], :single => true, :label => '' },
    :order => Proc.new() { |type,fld,f| f.select :order, [ [ 'None'.t, nil ], ['Ascending'.t, 'asc' ], ['Descending'.t, 'desc' ] ] }
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
  
  
  def preview_data
    raise 'Override me'
  end
  
end
