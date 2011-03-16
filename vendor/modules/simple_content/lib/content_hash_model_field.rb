
class ContentHashModelField < HashModel
  attr_accessor :content_model

  attributes :name => nil, :description => nil, :field => nil, :field_type => nil, :field_options => {}, :position => 0, :field_module => 'content/core_field', :publication_options => {}

  validates_presence_of :name
  validates_format_of :name, :with => /^[a-zA-Z][a-zA-Z0-9_\- .()#]{0,25}$/, :message => 'must begin with a letter and contain only numbers, letters, spaces and the following punctuation: _-#.()' 
  validates_presence_of :field_type
  validates_presence_of :field_module
  
  integer_options :position

  def initialize(model, hsh)
    self.content_model = model
    hsh ||= {}
    type = hsh[:field_type] || hsh['field_type']
    mod = hsh[:field_module] || hsh['field_module']
    self.field_type = type if type
    self.field_module = mod if mod
    super(hsh)
  end

  def strict?; true; end

  def id; self.field ? self.field.to_sym : nil; end

  def validate
    self.before_validation

    if self.field_type && self.field_module && self.field_options_model
      self.errors.add(:field_options,'are invalid') unless self.field_options_model.valid?
    end
  end

  def publication_options=(options)
    return unless options
    @publication_options = options.to_hash.symbolize_keys
  end

  def before_validation
    self.name = self.name.to_s.strip
  end
  
  def field_type=(type)
    return unless type

    vals = type.to_s.split('::')
    if vals.length == 2
      self.field_module = vals[0]
      @field_type = vals[1]
    else
      self.field_module ||= 'content/core_field'
      @field_type = type.to_s
    end
  end

  def text_value(data)
    if self.module_class
      content_display(data)
    else
      ''
    end
  end

  def field_options=(options)
    return @field_options if options.nil?

    if self.module_class
      options.each do |k,v|
        self.field_options_model.send("#{k}=", v)
      end

      @field_options = self.field_options_model.to_h.stringify_keys
    else
      @field_options = options
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

  def field_options_model
    self.module_class.field_options_model
  end

  alias_method :options, :field_options_model

  def field_options_partial
    self.module_class.field_options_partial
  end

  def publication_options_model
    return @publication_options_model if @publication_options_model

    @cls = Class.new(HashModel)
    self.module_class.display_options_variables.each do |fld|
      @cls.attributes(fld.to_sym => nil);
    end

    @publication_options_model = @cls.new(self.publication_options)
  end

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

  def setup_model(cls)
    self.module_class.setup_model(cls)
  end

  def content_field
    @content_field ||= ContentModel.content_field(self.field_module,self.field_type)
  end

  def representation
    self.content_field[:representation]
  end

  def modify_entry_parameters(parameters)
    self.module_class.modify_entry_parameters(parameters)
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
    self.module_class.content_display(entry,size,options)
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

  def data_field?;  self.module_class.data_field?; end

  def form_display_options(pub_field,f)
    self.module_class.form_display_options(pub_field,f)
  end

  def assign_value(entry,value)
    self.module_class.assign_value(entry,value)
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

  def is_type?(type)
    types = type.split("/")
    types.shift if types[0].blank?
    return self.field_module == types[0..-2].join("/") && self.field_type==types[-1]
  end

  def data_field?;  self.module_class.data_field?; end
end
