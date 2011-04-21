# Copyright (C) 2009 Pascal Rettig.

class ContentModelField < DomainModel
  validates_presence_of :name
  validates_format_of :name, :with => /^[a-zA-Z][a-zA-Z0-9_\- .()#]{0,25}$/, :message => 'must begin with a letter and contain only numbers, letters, spaces and the following punctuation: _-#.()' 
  validates_presence_of :field_type
  
  has_many :content_publication_fields, :dependent => :destroy

  belongs_to :content_model

  has_many :content_relations, :dependent => :delete_all

  named_scope :core_fields, lambda { |name|
    { :conditions => { :field_module => 'content/core_field',
                       :field_type => name } }
  }
  
#  acts_as_list

  def before_validation
    self.name = self.name.to_s.strip
  end
  
  def validate
    if self.module_class
      self.errors.add(:field_options,'are invalid') unless field_options_model.valid?
    end
  end

  serialize :field_options

  def field_type=(type)
    return unless type

    vals = type.to_s.split('::')
    if vals.length == 2
      self.field_module = vals[0]
      write_attribute :field_type, vals[1]
    else
      self.field_module ||= 'content/core_field'
      write_attribute :field_type, type.to_s
    end
  end

  def text_value(data)
    if self.module_class
      content_display(data)
    else
      ''
    end
  end
  
  def module_class
    return @module_class if @module_class
    return nil unless self.field_type && self.field_module
    field_class = self.field_type + "_field"
    cls = "#{self.field_module.classify}::#{field_class.classify}".constantize
    @module_class ||= cls.new(self)
  end

  def default_field_name
    self.module_class.default_field_name
  end
  
  def entry_attributes(parameters)
    self.module_class.entry_attributes(parameters)
  end
  
  def modify_entry_parameters(parameters)
    self.module_class.modify_entry_parameters(parameters)
  end

  def is_type?(type)
    types = type.split("/")
    types.shift if types[0].blank?
    return self.field_module == types[0..-2].join("/") && self.field_type==types[-1]
  end

  def data_field?;  self.module_class.data_field?; end

  def required?
    self.field_options['required']
  end
  
  def form_field(f,options={})
    options.symbolize_keys!

    field_name = options.delete(:field)
    field_name = self.module_class.default_field_name unless field_name
    
    field_size = options.delete(:size).to_i
    field_size = 40 if field_size == 0 
    
    required = self.required?
    
    label = options.delete(:label) || self.name
    noun = options.delete(:noun) || label
    
    field_display_opts = {:size => field_size || 40, :label => label, :required => required, :noun => noun}
    if options[:editor]
      field_display_opts[:description] = self.description.blank? ? nil : self.description
    end  
    self.module_class.form_field(f,field_name,field_display_opts,options)
  end


  # Return the actual class if this field has a relation
  # but only 
  def content_model_relation
    if !self.field_options['relation_class'].blank?
      ContentModel.content_model_details(self.field_options['relation_class'])
    else
      nil
    end
  end


  # Return the actual class if this field has a relation
  def relation_class
    cls = self.relation_class_name
    cls.constantize if cls && cls.to_s.downcase != 'other'
  end


  # Return the actual class if this field has a relation
  def relation_class_name
    if !self.field_options['relation_class'].blank?
      begin
        return self.field_options['relation_class']
      rescue Exception => e
        return nil
      end
    else
      nil
    end
  end

  def relation_name
    !self.field_options['relation_name'].blank? ? self.field_options['relation_name'] :self.field
  end

  def feature_tag_name
    !self.field_options['relation_name'].blank? ? self.field_options['relation_name'] :self.field
  end

  def site_feature_value_tags(c,name_base,size=:full,options={})
    options[:local] ||= 'entry'
    self.module_class.site_feature_value_tags(c,name_base,size,options)
  end
  
  def content_display(entry,size=:full,options={})
    self.module_class.content_display(entry,size,options.symbolize_keys)
  end

  def content_value(entry)
    self.module_class.content_value(entry)
  end

  def content_export(entry)
    self.module_class.content_export(entry)
  end

  def content_import(entry,value)
    self.module_class.content_import(entry,value)
  end
  
  def filter_variables
    self.module_class.filter_variables
  end

  def filter_names
    self.module_class.filter_names
  end
  
  def filter_conditions(options,filter_opts)
    if filter_opts[:filter] == 'filter'
      self.module_class.filter_conditions(options,filter_opts)
    elsif filter_opts[:filter] == 'fuzzy'
      self.module_class.fuzzy_filter_conditions(options,filter_opts)
    end
  end

  def filter_display(opts)
    self.module_class.filter_display(opts)
  end

  def escaped_field
    "`#{self.content_model.table_name}`.`#{self.field}`"
  end

  def filter_options(f,name=nil,attr={})
    self.module_class.filter_options(f,name,attr.symbolize_keys)
  end
  
  def setup_model(cls)
    self.module_class.setup_model(cls)
  end
  
  
  def set_field_options(options)
    self.module_class.set_field_options(options) || {}
  end
  
  def active_table_header
    self.module_class.active_table_header
  end
  
  
  def field_options_model
    self.module_class.field_options_model
  end

  alias_method :options, :field_options_model
  
  def field_options_partial
    self.module_class.field_options_partial
  end
  
  def display_options_variables
    self.module_class.display_options_variables
  end
  
  def display_options(pub_field,f)
    self.module_class.display_options(pub_field,f)
  end
  
  def form_display_options(pub_field,f)
    self.module_class.form_display_options(pub_field,f)
  end

  def filter_display_options(pub_field,f)
    self.module_class.filter_display_options(pub_field,f)
  end
  
  def dynamic_value(dynamic_field,entry,application_state={})
    cls, meth = ContentModel.dynamic_field_info(dynamic_field)
    
    if cls && meth
      cls.send(meth,entry,self,application_state)
    else
      nil
    end
  end    
  
  def assign_value(entry,value)
    self.module_class.assign_value(entry,value)
  end
  
  def assign(entry,values)
    self.module_class.assign(entry,values)
  end

  def after_save
    self.add_has_many_relationship if self.field_type == 'belongs_to' && self.field_options['add_has_many']
  end

  def add_has_many_relationship
    return if self.relation_name == 'end_user' || self.relation_name == 'other' || self.relation_class == 'Other'

    table_name = self.content_model.table_name
    plural_name = "#{self.field.sub(/_id$/,'')}_#{table_name.sub(/^cms_/, '')}"
    singular_name = plural_name.singularize
    field_id = "#{singular_name}_id"
    cm = ContentModel.find_by_table_name self.relation_class.table_name
    return if cm.content_model_fields.detect { |fld| fld.field_type == 'has_many_simple' && fld.field == field_id }

    options = Content::Field::FieldOptions.new :relation_class => table_name.classify, :relation_name => plural_name, :relation_singular => singular_name, :foreign_key => self.field

    next_position = cm.content_model_fields.maximum(:position) + 1
    cm.content_model_fields.create :name => plural_name.titleize, :field => field_id, :field_type => 'has_many_simple', :field_options => options.to_h.stringify_keys, :field_module => 'content/core_field', :position => next_position
  end
end
