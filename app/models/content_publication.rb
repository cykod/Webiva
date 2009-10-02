# Copyright (C) 2009 Pascal Rettig.

class ContentPublication < DomainModel
  validates_presence_of :name
  validates_presence_of :publication_type
  validates_presence_of :content_model
  
  has_options :publication_type,
                  [ [ 'Entry Create Form', 'create' ],
                           [ 'Entry Display', 'view' ],
                           [ 'Entry List', 'list' ],
                           [ 'Entry Edit Form', 'edit' ],
                           [ 'Admin List', 'admin_list' ],
                           [ 'Data Output', 'data' ] ]
  
  belongs_to :content_model
  serialize :data
  serialize :actions
  
  has_many :content_publication_fields, :dependent => :destroy, :order => 'content_publication_fields.position', :include => :content_model_field
  
  has_many :page_paragraphs, :dependent => :destroy
  
  has_triggered_actions  

  public
  
  
  def options(val=nil)
    self.publication_type_class.options(val)
  end
  
  def options_partial
    self.publication_type_class.options_partial
  end
  
  def publication_module_class
    self.publication_module.classify.constantize
  end
  
  def publication_type_class
    return @publication_type_class if @publication_type_class
    type_class = self.publication_type + "_publication"
    cls = "#{self.publication_module.classify}::#{type_class.classify}".constantize
    @publication_type_class ||= cls.new(self)
  end
  
  def before_create
    self.feature_name =  self.content_model.name.downcase.gsub(/[^a-z0-9]/,"_")[0..20] + "_" + self.name.downcase.gsub(/[^a-z0-9]/,"_")[0..20] + "_publication"
  end
  
  def add_all_fields!
    self.content_model.content_model_fields.each do |fld|
    self.content_publication_fields.create(
				:label => fld.name,
				:field_type => self.field_type_options[0][1],
				:data => {},
				:content_model_field_id => fld.id
				)
  	end
  end
  
  
  def update_entry(entry,values = {},application_state = {})
    application_state = application_state.merge({:values => values })
    
    self.content_publication_fields.each do |fld|
      val = nil
      case fld.field_type
      when 'dynamic':
        val = fld.content_model_field.dynamic_value(fld.data[:dynamic],application_state)
        fld.content_model_field.assign_value(entry,val)
      when 'input':
        fld.content_model_field.assign(entry,values)
      when 'preset':
        fld.content_model_field.assign_value(entry,fld.data[:preset])
      end
    end
    entry
  end
  
  
  def form?
    self.publication_type_class.respond_to?(:render_form)
  end
  
  def html?
    self.publication_type_class.respond_to?(:render_html)
  end
  
  def render_form(f,options={})
    self.publication_type_class.render_form(f,options) if form?  
  end
  
  def render_html(content,options={})
    self.publication_type_class.render_html(content,options) if html?  
  end
  

  def field_type_options
    self.publication_type_class.field_type_options
  end 
  
  def renderer_class
    cls_name = self.publication_module_class.type_hash[self.publication_type.to_sym][:renderer]
    cls_name.classify.constantize
  end
  
  def custom_field_types
    self.publication_type_class.custom_field_types
  end
  
  def field_options(val=nil)
    self.publication_type_class.field_options_class.new(val)
  end
  
  def field_options_form_elements(fld,f)
    self.publication_type_class.field_options(fld,f)
  end

  def triggers
    self.publication_type_class.triggers
  end
  
  def generate_preview_data
    self.publication_type_class.preview_data
  end
  
  def filter_variables
    returning filter_vars = [] do
      self.content_publication_fields.each do |fld|
        if (fld.data[:options] || []).include?('filter')
          filter_vars.concat(fld.filter_variables)
        end
      end
    end
  end
  
  def filter_form_elements(f)
    output = ""
    self.content_publication_fields.each do |fld|
      if (fld.data[:options] || []).include?('filter')
        output << fld.filter_options(f)
      end
    end
    output
  end
  
  def get_filter_conditions(options)
  
    order = []
    
    conditions = options[:conditions] || ['1']
    conditions = [ conditions ] unless conditions.is_a?(Array)
    
    values = options[:values] || []
    
        
    self.content_publication_fields.each do |fld|
      if fld.data[:order]
        if fld.data[:order] == 'asc'
          order << "`#{fld.content_model_field.field}` ASC"
        elsif fld.data[:order] == 'desc'
          order << "`#{fld.content_model_field.field}` DESC"
        end
      end

      fld_conditions, fld_values = fld.filter_conditions(options)
      
      conditions << fld_conditions if fld_conditions
      values += fld_values if fld_values
      
    end
          
    if order.length > 0
      order = order.join(",")
    else
      order = nil
    end
    
    offset = options[:offset] if options[:offset]
    
    include_joins = []
    if(self.content_model.show_tags?)

      tags = (options[:tags]||[]).find_all() { |elm| !elm.blank? }
      if tags.length > 0
        conditions << 'content_tags.id IN (?)'
        values << tags
        include_joins << 'content_tags'
      end
    end
    

    return { :conditions => [ conditions.join(" AND ") ] + values, :order => order, :offset => offset, :include => include_joins }
  
  end
  
  def get_list_data(page = 1,options = {})
    return nil  unless %w(list admin_list data).include?(self.publication_type)
    
    filter_options = get_filter_conditions(options)
    
    mdl = self.content_model.content_model
    
    per_page = (options[:per_page] || self.options.entries_per_page || self.options.entries_displayed).to_i
    per_page = :all if per_page == 0
    
    filter_options[:per_page] =  per_page
    
    mdl.paginate(page, filter_options)
  end
  
  
  def get_random_entry(options = {})
    filter_options = get_filter_conditions(options)
    
    mdl = self.content_model.content_model
    
    cnt = mdl.count(:all,:conditions => filter_options[:conditions])
    
    num = rand(cnt)
    mdl.find(:first,:conditions => filter_options[:conditions], :offset => num)
  end
  
  def get_field_entry(field,val, options = {})
    mdl = self.content_model.content_model
    if mdl.columns_hash[field.to_s] && val
      filter_options = get_filter_conditions(options)
      filter_options[:conditions][0] += " AND #{field} = ?"
      filter_options[:conditions] << val
      
      cnt = mdl.count(:all,:conditions => filter_options[:conditions])
      
      if cnt > 0
        num = rand(cnt)
      else
        num = 0
      end
      mdl.find(:first,:conditions => filter_options[:conditions], :offset => num)
    else
      return nil
    end
  end
  
  
  # Get a specific entry id or the first entry, but make sure it matches
  # the filter conditions
  def get_filtered_entry(entry_id,options = {})
    filter_options = get_filter_conditions(options)
    
    mdl = self.content_model.content_model
    
    return nil if entry_id.blank?
    
    if entry_id.to_sym == :first
      filter_options[:order] = 'id' unless filter_options[:order]
      mdl.find(:first,:conditions => filter_options[:conditions],:order => filter_options[:order], :offset => filter_options[:offset] )
    else
      mdl.find_by_id(entry_id,:conditions => filter_options[:conditions])
    end
  end
  
  def get_filtered_count(options = {})
    return nil unless self.publication_type == 'view'
    
    filter_options = get_filter_conditions(options)
    
    mdl = self.content_model.content_model
    mdl.count(:all,:conditions => filter_options[:conditions])
  end
  
  
  def self.get_publication_paragraphs
    [ 'Publications' ] + 
    self.find(:all, :order => 'name').collect do |pub|
      ["editor", pub.publication_type, pub.content_model.name + " - " + pub.name, "/editor/publication", [pub.feature_name],pub.id ]
    end
  end
  
  def self.get_publication_features
    self.find(:all,:order => 'name',:conditions => 'feature_name IS NOT null').collect do |feat|
      [ feat.feature_name.humanize.capitalize, feat.feature_name, feat.id ]
    end
    
  end
  
  
  def default_feature
    self.publication_type_class.default_feature
  end 
  
  def generate_default_feature_data
    raise 'Use default feature instead'
  end
  
  def filter_input_fields(parameters)
    output_params = {}
    self.content_publication_fields.each do |fld|
      if fld.field_type == 'input' && parameters.has_key?(fld.content_model_field.field)
        output_params[fld.content_model_field.field] = parameters[fld.content_model_field.field]
      end
    end
  
    output_params
  end
  
  


 
end
