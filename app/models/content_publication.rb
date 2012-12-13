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
                           [ 'Admin List', 'Admin_list' ],
                           [ 'Data Output', 'data' ] ]
  
  belongs_to :content_model
  serialize :data
  serialize :actions

  attr_accessor :start_empty
  
  has_many :content_publication_fields, :dependent => :destroy, :order => 'content_publication_fields.position', :include => [ :content_model_field, :content_publication ]
  
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

  def primary_feature
    @primary_feature ||= SiteFeature.find(:first,:conditions => { :feature_type => self.feature_name },:order => "id")
  end
  
  def before_create
    self.feature_name =  self.content_model.name.downcase.gsub(/[^a-z0-9]/,"_")[0..20] + "_" + self.name.downcase.gsub(/[^a-z0-9]/,"_")[0..20] + "_publication"
  end

  def feature_method_name
    self.publication_type_class.feature_method_name
  end
  
  def add_all_fields!
    self.content_model.content_model_fields.find(:all,:order => 'position').each_with_index do |fld,idx|
    self.content_publication_fields.create(
				:label => fld.name,
				:field_type => self.field_type_options[0][1],
				:data => {},
				:content_model_field_id => fld.id,
                                 :position => idx
				)
  	end
  end

  
  def assign_entry(entry,values = {},application_state = {})
    application_state = application_state.merge({:values => values })
    values = self.content_model.entry_attributes(values) 
    self.content_publication_fields.each do |fld|
      val = nil
      case fld.field_type
      when 'dynamic':
          val = fld.content_model_field.dynamic_value(fld.data[:dynamic],entry,application_state)
        fld.content_model_field.assign_value(entry,val)
      when 'input':
          fld.content_model_field.assign(entry,values)
      when 'preset':
          fld.content_model_field.assign_value(entry,fld.data[:preset])
      end
    end
    entry.valid?
    
    self.content_publication_fields.each do |fld|
      if fld.data && fld.data[:required]
        if fld.content_model_field.content_value(entry).blank?
          entry.errors.add(fld.content_model_field.field,'is missing')
        end
      end
    end

    entry
  end
  
  def update_entry(entry,values = {},application_state = {})
    entry = assign_entry(entry,values,application_state)

    if entry.errors.length == 0
      entry.save 
    else
      false
    end
  end

  def form?
    self.publication_type_class.respond_to?(:render_form)
  end

  def filter?
     self.publication_type_class.filter?
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

  def each_page_connection_input
    self.content_publication_fields.each do |fld|
      yield fld.content_model_field.field.to_sym,fld
    end
  end

  def page_connections
    info = {}
    self.content_publication_fields.each do |fld|
      if fld.options.filter_options.include?('connection')
        info[:inputs] ||= {}
        info[:inputs][fld.content_model_field.field.to_sym] = []


        if fld.content_model_field.is_type?('content/core_field/belongs_to')
          if fld.content_model_field.relation_class == EndUser
            info[:inputs][fld.content_model_field.field.to_sym] <<
            [ "filter_#{fld.content_model_field.relation_name}".to_sym, fld.content_model_field.relation_name, :user_target]
          end
          info[:inputs][fld.content_model_field.field.to_sym] <<
            [ "filter_#{fld.content_model_field.field}".to_sym, "#{fld.content_model_field.relation_name} ID", :path]
          info[:inputs][fld.content_model_field.field.to_sym] <<
            [ "filter_content_#{fld.content_model_field.field}".to_sym, "#{fld.content_model_field.relation_name} Content", :content]
        else
          fld.filter_variables.each do |filter_var|
            info[:inputs][fld.content_model_field.field.to_sym] <<
            [ filter_var.to_sym, filter_var.to_s.humanize, :path ]
          end
        end
      end
    end


    # Disable publication outputs for now
    self.content_publication_fields.each do |fld|
      if false && fld.options.filter_options.include?('connection')
        info[:outputs] ||= []
        info[:outputs] << [fld.content_model_field.field.to_sym,
                           fld.content_model_field.name,
                           :path]
        info[:outputs] << [fld.content_model_field.field.to_sym,
                           fld.content_model_field.name,
                           "#{fld.content_model_field.field_type}_field".to_sym]
      end
    end
    info
  end
  
  def filter_variables
    returning filter_vars = [] do
      self.content_publication_fields.each do |fld|
        if (fld.options.filter)
          filter_vars.concat(fld.filter_variables)
        end
      end
    end
  end
  
  def filter_form_elements(f)
    output = ""
    self.content_publication_fields.each do |fld|
      if (fld.data[:filter] == 'filter' || fld.data[:filter] == 'fuzzy')
        output << fld.filter_options(f)
      end
    end
    output
  end

  # return a hash of find arguments for this publication
  # given as set of admin options and a set of user submitted
  # form_options which are only used on filters that are exposed
  def filter_conditions(options={},form_options={})
    options = options.symbolize_keys
    form_options = form_options.symbolize_keys

    filter = {
      :order => [],
      :conditions => [],
      :joins => [],
      :values => [],
      :includes => [],
      :score => [],
      :count => [],
      :select => []
    }

    filter[:joins] = [ options[:joins] ] if options[:joins]
    filter[:select] = [ options[:select] ] if options[:select]

    if options[:conditions]
      if options[:conditions].is_a?(Array)
        filter[:conditions] << options[:conditions][0]
        filter[:values] += options[:conditions][1..-1] if options[:conditions].length > 1
      else
        filter[:conditions] << options[:conditions]
      end
    end

    filter[:order] << options[:order] if options[:order]
    
    self.content_publication_fields.each do |fld|
      
      fld_options = fld.filter_conditions(options,form_options)

      if fld_options
        fld_options.each do |key,val|
          next if val.nil?
          val = [ val ] unless val.is_a?(Array)
          filter[key] ||= []
          filter[key] += val

          # If we have a score, but don't have a separate count/where
          # statement, assume this score statement is ok for
          # both a content_score and a WHERE/count condition
          # e.g. IF(field="spam",1,0) is ok in a count
          # e.g. COUNT(content_relations.id) is not ok (group field) -
          # need to replace with content_relations.id IS NOT NULL
          # so each filter handles the second case itself, but the
          # first case we need to make it an automatic count condition
          %w(a b c).each do |fuzzy_filter|
            if key == "score_#{fuzzy_filter}".to_sym && !fld_options["count_#{fuzzy_filter}".to_sym]
              filter["count_conditions_#{fuzzy_filter}".to_sym] ||= []
              filter["count_conditions_#{fuzzy_filter}".to_sym] += val
            end
          end
        end

      end
      if fld.data[:order]
        if fld.data[:order] == 'asc'
          filter[:order] << "#{fld.escaped_field} ASC"
        elsif fld.data[:order] == 'desc'
          filter[:order] << "#{fld.escaped_field} DESC"
        end
      end


    end

    if(self.content_model.show_tags?)

      tags = (options[:tags]||[]).find_all() { |elm| !elm.blank? }
      if tags.length > 0
        filter[:conditions] << 'content_tag_tags.content_tag_id IN (?)'
        filter[:values] << tags
        filter[:joins] << "INNER JOIN content_tag_tags ON (`#{content_model.table_name}`.id = content_tag_tags.content_id AND content_tag_tags.content_type = #{content_model.connection.quote(content_model.table_name.classify)})"
      end
    end

    
    # Generate a find-friendly options hash output
    filter_output = {}
  
    if filter[:joins].length > 0
      filter_output[:joins] = filter[:joins].uniq.join(" ")
      filter_output[:group] = "`#{content_model.table_name}`.id"
    end

    %w(a b c).each do |fuzzy_filter|
      score_sym = "score_#{fuzzy_filter}".to_sym
      if filter[score_sym] && filter[score_sym].length > 0
        score = filter[score_sym].uniq.join(" + ")
        filter_output[:select] ||=  [] 
        filter_output[:select] << "`#{content_model.table_name}`.id, (#{score}) as content_score_#{fuzzy_filter}" 

        extra_conditions = []
        if filter["count_conditions_#{fuzzy_filter}".to_sym]
          extra_conditions << "(" + filter[ "count_conditions_#{fuzzy_filter}".to_sym].join(" + ") + ") > 0"
        end
        extra_conditions += filter["count_#{fuzzy_filter}".to_sym] if filter["count_#{fuzzy_filter}".to_sym]
        if extra_conditions.length > 0
          filter[:conditions] << extra_conditions.map { |elm| "(#{elm})" }.join(" OR ")
        end
        
        filter[:order].unshift("content_score_#{fuzzy_filter} DESC")
        filter_output[:group] = "`#{content_model.table_name}`.id"
      end
    end

    if filter[:conditions].length > 0
      filter_output[:conditions] = [ filter[:conditions].map { |elm| "(#{elm})" }.join(" AND ") ] + filter[:values]
      filter_output[:conditions] = filter_output[:conditions][0] if filter_output[:conditions].length == 1
    end

    
    if filter[:order].length > 0
      filter_output[:order] = filter[:order].uniq.join(", ")
    end

    if filter[:includes].length > 0
      filter_output[:includes] = filter[:includes]
    end


    filter_output[:offset] = options[:offset] if options[:offset]

    filter_output[:select] ||= []
    filter_output[:select] += [ options[:select] ] if options[:select]
    if filter_output[:select].length > 0
      filter_output[:select] = filter_output[:select].join(',') 
    else
      filter_output.delete(:select)
    end
    
    return filter_output
  end

  def get_full_data(options={ },form_options={ })

    return nil  unless %w(list admin_list data).include?(self.publication_type)
    
    filter_options = filter_conditions(options,form_options)

    mdl = self.content_model.content_model
    
    data = mdl.find(:all, filter_options)

    resolve_filtered_data(data,filter_options) || []
  end

  
  def get_list_data(page = 1,options = {},form_options = {})
    return nil  unless %w(list admin_list data).include?(self.publication_type)
    
    filter_options = filter_conditions(options,form_options)

    mdl = self.content_model.content_model
    
    per_page = (options[:per_page] || self.options.entries_per_page || self.options.entries_displayed).to_i
    per_page = :all if per_page == 0
    
    filter_options[:per_page] =  per_page


    pages,data = mdl.paginate(page, filter_options)

    [ pages, resolve_filtered_data(data,filter_options) ]
  end

  # we might just have a bunch of classes with a id & a score
  # need to pull the actual data out
  def resolve_filtered_data(data,filter_options=[])
    if !data.is_a?(Array)
      data = [ data]
      single = true
    else
      single = false
    end
    return nil unless data[0]
    
    if data[0].attributes['content_score_a'] || data[0].attributes['content_score_b'] || data[0].attributes['content_score_c']
      elems = data[0].class.find(:all,:include => filter_options[:include], :conditions => { :id => data.map(&:id) }).index_by(&:id)
      output = data.map do |elm|
        row = elems[elm.id]
        if row
          row.content_score_a = elm.attributes['content_score_a'].to_i
          row.content_score_b = elm.attributes['content_score_b'].to_i
          row.content_score_c = elm.attributes['content_score_c'].to_i
          row
        else
          nil
        end
      end.compact
      single ? output[0] : output
    else
      single ? data[0] : data
    end
  end
  
  
  def get_random_entry(options = {},form_options = {})
    filter_options = filter_conditions(options,form_options)
    
    mdl = self.content_model.content_model
    
    cnt = mdl.count(:all,:conditions => filter_options[:conditions])
    
    num = rand(cnt)
    resolve_filtered_data(mdl.find(:first,:conditions => filter_options[:conditions], :offset => num),filter_options)
  end
  
  def get_field_entry(field,val, options = {},form_options ={})
    mdl = self.content_model.content_model
    if mdl.columns_hash[field.to_s] && val
      filter_options = filter_conditions(options,form_options)
      filter_options[:conditions][0] += " AND #{field} = ?"
      filter_options[:conditions] << val
      
      cnt = mdl.count(:all,filter_options.slice( :conditions, :joins, :include, :distinct, :having))
      
      if cnt > 0
        num = rand(cnt)
      else
        num = 0
      end
      resolve_filtered_data(mdl.find(:first,:conditions => filter_options[:conditions], :offset => num),filter_options)
    else
      return nil
    end
  end
  
  
  # Get a specific entry id or the first entry, but make sure it matches
  # the filter conditions
  def get_filtered_entry(entry_id,options = {},form_options = {})
    filter_options = filter_conditions(options,form_options)
    
    mdl = self.content_model.content_model
    
    return nil if entry_id.blank?
    
    if entry_id.to_sym == :first
      filter_options[:order] = 'id' unless filter_options[:order]
      resolve_filtered_data(mdl.find(:first,filter_options),filter_options)
    else
      mdl.find_by_id(entry_id,filter_options)
    end
  end
  
  def get_filtered_count(options = {},form_options = {})
    return nil unless self.publication_type == 'view'
    
    filter_options = filter_conditions(options,form_options)
    
    mdl = self.content_model.content_model
    mdl.count(:all, filter_options.slice( :conditions, :joins, :include, :distinct, :having))
  end
  
  
  def self.get_publication_paragraphs
    [ 'Publications' ] + 
    self.find(:all, :order => 'name', :conditions => 'publication_type != "data"').collect do |pub|
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
