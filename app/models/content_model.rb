# Copyright (C) 2009 Pascal Rettig.

require 'csv'

class ContentModel < DomainModel
  validates_presence_of :name
  
  validates_uniqueness_of :name
  
  has_many :content_model_fields, :order => :position, :dependent => :destroy
  has_many :content_model_features, :order => :position, :dependent => :destroy
  has_many :content_publications, :order => :name, :dependent => :destroy

  content_node_type :content,Proc.new { |cm| cm.table_name.blank? ? "__dummy__" : cm.table_name.camelcase } ,:title_field => :identifier_name, :search => false
  
  accepts_nested_attributes_for :content_model_features, :allow_destroy => true

  serialize :options


  include SiteAuthorizationEngine::Target
  
  access_control :view_access_control
  access_control :edit_access_control
  
  def before_save
    if self.model_preset.blank?
      self.model_preset = 'custom'
      self.customized = true
    end
  end

  
  include Content::MigrationSupport      # Support for creating update content tables
  include Content::ContentModelGenerator # Support for creating the Anonymous content model classes
  include Content::ImportSupport         # Support for import/export functionality


  def can_edit?(user)
    if self.edit_access_control?
      user.has_role?(:edit_access_control,self)
    else
      user.has_role?(:editor_content)
    end
  end
  
   # Return a list of content fields with their modules added in
  def self.content_fields
    returning fields = [] do
      get_handler_info(:content,:fields).each do |info|
        fields.concat(info[:class].fields)
      end
    end
    
  end
  
   # Return a hash of content fields with their modules added in
  def self.content_fields_hash
    returning field_hash = {} do 
      get_handler_info(:content,:fields).each do |info|
        field_hash[info[:identifier]] = info[:class].field_hash
      end
    end
  end

  def self.content_field_options
    self.content_fields.collect { |fld| [ fld[:description].t, fld[:name] ] }
  end
  
  def all_fields
    [ContentModelField.new( :field_type=>:integer, :field_module => 'content/core', :field => 'id', :name => 'Identifier'.t)] + self.content_model_fields
  end
  
  def self.content_field(field_module,name)
    (content_fields_hash[field_module.to_s]||{})[name.to_sym] || nil
  end
  
  def self.content_field_class(field_module)
    field_module.classify.constantize
  end
  
  def content_field(field_module,name) 
    self.class.content_field(field_module,name)
  end
  
  def self.dynamic_field_options(field_module,name)
    if content_fields_hash[field_module]
      available_fields = (content_fields_hash[field_module.to_s][name.to_sym]||{})[:dynamic_fields] || []

      # only get the dynamic fields this field supports      
      field_list = field_module.classify.constantize.dynamic_fields.select { |fld| available_fields.include?(fld[:name]) }
      
      # now turn them into options
      field_list.map { |fld| [ fld[:label], "#{fld[:module]}:#{fld[:name]}" ] }
    end
    # TODO add in any dynamic fields from other modules
  end
  
  def self.dynamic_fields_class(dynamic_value_module)
    if content_fields_hash[dynamic_value_module]
      dynamic_value_module.classify.constantize
    else
      {}
    end
  end
  
  def self.dynamic_field_info(field_name)
    info = field_name.split(":")
    
    # Handle legacy fields that have no module
    if info.length == 2
      module_info = info[0]
      field_info = info[1]
    else
      module_info = 'content/core_field'
      field_info = info[0]
    end
    
    field_class = dynamic_fields_class(module_info)
    
    # return the class and the calling method
    if field_class && field_class.dynamic_field_hash[field_info.to_sym]
      field_method = "dynamic_#{field_info}_value"
      [ field_class, field_method ]
    else
      nil
    end
  end
  
  def field(name)
    name = name.to_s
    self.content_model_fields.detect { |elm| elm.field == name }
  end
  
  def self.relationship_classes
    content_models = ContentModel.find(:all,:order => 'name')
    clses = [ [ 'User', 'end_user' ] ] + content_models.collect { |mdl| [ mdl.name, mdl.table_name ] }
  end

  def self.content_model_details(name)
     name = name.underscore.pluralize
     cm = ContentModel.find_by_table_name(name,:include => :content_model_fields)
  end
  
  def self.content_model(name)
    cls = DataCache.local_cache("content_model_table_#{name}")
    return cls if cls

    
    cm = ContentModel.find_by_table_name(name,:include => :content_model_fields)
    return nil unless cm
    DataCache.put_local_cache("content_model_table_#{name}", cm.content_model)
  end
  
  def entry_attributes(parameters)
    parameters = parameters.clone
    self.content_model_fields.each do |fld|
      fld.modify_entry_parameters(parameters)
    end
    parameters
  end
  
  def update_entry(entry,parameters,user=nil)
    if self.create_nodes?
      return entry.save_content(user,entry_attributes(parameters))
    else
      return entry.update_attributes(entry_attributes(parameters))
    end
  end
  
  
  def process_fields(fields)
    all_valid = true
    returning cm_fields = [] do 
      fields.each do |fld|
        fld_id = fld.delete(:id)
        cm_field = self.content_model_fields.detect { |cm| cm.id == fld_id.to_i } if fld_id
        if !cm_field
          cm_field = self.content_model_fields.build
        end
        
        cm_field.attributes = fld
        all_valid = false unless cm_field.valid?
        
        cm_fields << cm_field
      end
    end
    
    [ cm_fields, all_valid ]
  end
  
  
  def self.state_select_options(ca_provinces=false)
     states = ["AL","AK","AR","AS","AZ","CA","CO","CT","DC","DE","FL","FM","GA","GU","HI","IA","ID","IL", "IN","KS","KY","LA","MA","MD","ME","MH","MI","MN","MO","MP","MS","MT","NC","ND","NE","NH","NJ","NM","NV", "NY","OH","OK","OR","PA","PR","PW","RI","SC","SD","TN","TX","UT","VA","VI","VT","WA","WI","WV","WY" ] +
      (ca_provinces ? [ "ON","QC","NS","NB","MB","BC","PE","SK","AB","NL" ] : [])
      
    ca_provinces ? states.sort : states
  end
  
  
  def model_generator_features
    self.content_model_features.select { |feature| feature.model_generator_callback? }
  end
  
end

