# Copyright (C) 2009 Pascal Rettig.

module Validateable #:nodoc:
  [:save, :save!, :update_attribute].each{|attr| define_method(attr){}}
  
  def new_record?; false; end
  
  def method_missing(symbol, *params)
    if(symbol.to_s =~ /(.*)_before_type_cast$/)
      send($1)
    end
  end
  def self.append_features(base)
    super
    base.send(:include, ActiveRecord::Validations)
  end
  
end

=begin rdoc
HashModel's are used throughout webiva 


=end
class HashModel 
  include Validateable
  include WebivaValidationExtension
  include ModelExtension::OptionsExtension
  
  def self.defaults
    {}
  end
  
  def defaults
    self.class.defaults
  end
  
  def self.attributes(hsh) 
    hsh.symbolize_keys!
    
    int_opts = []
    class_eval do
      hsh.each do |atr,val|
        attr_accessor atr.to_sym
        
        if atr.to_s =~ /_(id)$/ 
          int_opts << atr.to_sym
        end
      end
      
      df = self.defaults.merge(hsh)
      class << self; self end.send(:define_method,"defaults") do
        df
      end
    end
    integer_options(int_opts)
  end
  
  def self.default_options(hsh)
    hsh.symbolize_keys!
    
    int_opts = []
    class_eval do
      hsh.each do |atr,val|
        attr_accessor atr.to_sym
      end
    
      define_method "defaults" do
         return hsh
      end 
      
    end
  end
  
  def self.current_integer_opts; []; end
  def self.current_page_opts; []; end
  def self.current_boolean_opts; []; end
  def self.current_float_opts; []; end
  def self.current_integer_array_opts; []; end

  def self.integer_options(*objs)
    if objs[0].is_a?(Array)
      objs = current_integer_opts + objs[0]
    else
      objs = current_integer_opts + objs
    end
    objs.uniq!
    
    class << self; self end.send(:define_method,"current_integer_opts") do
      objs
    end
  end


   def self.integer_array_options(*objs)
    if objs[0].is_a?(Array)
      objs = current_integer_array_opts + objs[0]
    else
      objs = current_integer_array_opts + objs
    end
    objs.uniq!
    
    class << self; self end.send(:define_method,"current_integer_array_opts") do
      objs
    end
  end
  
  def self.boolean_options(*objs)
    objs = current_boolean_opts + objs
    
    objs.uniq!
    class << self; self end.send(:define_method,"current_boolean_opts") do
      objs
    end

    objs.each do |obj|
      self.class_eval <<-EOF
      def #{obj}?
        ! @#{obj}.blank?
      end
      EOF
    end
  end

  def self.float_options(*objs)
    objs = current_float_opts + objs

    objs.uniq!
    class << self; self end.send(:define_method,"current_float_opts") do
      objs
    end
  end
  
  def self.date_options(*atrs)
    atrs.each do |atr|
      self.class_eval <<-EOF
      def #{atr}_date
        begin
          @#{atr}_date ||= Time.parse self.#{atr}
        rescue
        end
      end
      EOF
    end
  end
  
  def self.page_options(*atrs)
    atrs.each do |atr|
      if atr.to_s =~ /^(.*)_id$/
        name = $1
        self.class_eval <<-EOF
        def #{name}_url
          return @#{name}_url if @#{name}_url
          @#{name}_url = SiteNode.node_path(self.#{atr})
        end
        def #{name}_node
          return @#{name}_node if @#{name}_node
          @#{name}_node = SiteNode.find_by_id(self.#{atr})
        end
        EOF
      end
    end

    if atrs[0].is_a?(Array)
      atrs = current_page_opts + atrs[0]
    else
      atrs = current_page_opts + atrs
    end
    atrs.uniq!
    
    class << self; self end.send(:define_method,"current_page_opts") do
      atrs
    end
  end

  def fix_page_options(to_version)
    return false if self.class.current_page_opts.empty?

    self.class.current_page_opts.each do |fld|
      nd = SiteNode.find_by_id(send(fld))
      next unless nd
      new_node = to_version.site_nodes.find_by_node_path(nd.node_path)
      self.instance_variable_set "@#{fld}", new_node ? new_node.id : nil
    end

    true
  end

  def self.registered_options_form_fields()
    nil
  end

  def self.options_form(*fields)
    fields = (self.registered_options_form_fields||[]) + fields
    class << self; self; end.send(:define_method,:registered_options_form_fields) do
      fields
    end
  end
  
  def options_locals(f)
    if self.class.registered_options_form_fields
      {  :f => f, :fields => self.class.registered_options_form_fields, :options => self }
    else
      { }
    end
  end

  def options_partial
    if self.class.registered_options_form_fields
      "/application/options_partial"
    else
      nil
    end
  end

  FormField = Struct.new(:name,:field_type,:options)

  def self.fld(name,field_type,options={ })
    FormField.new(name,field_type,options)
  end

  def self.domain_file_options(*atrs)
    atrs.each do |atr|
      if atr.to_s =~ /^(.*)_id$/
        name = $1
        self.class_eval <<-EOF
        def #{name}_file(force=false)
          return @#{name}_file if @#{name}_file && !force
          @#{name}_file = DomainFile.find_by_id(self.#{atr})
        end

        def #{name}(force=false)
          self.#{name}_file(force)
        end

        def #{name}_url(size=nil)
          fl = #{name}_file
          if fl
            fl.url(size)
          else
            nil
          end
        end

        def #{name}_full_url(size=nil)
          fl = #{name}_file
          if fl
            fl.full_url(size)
          else
            nil
          end
         end
        EOF
      end
    end
  end
  
  def initialize(hsh)
  	hsh ||= {}
    sym_hsh = {}
    hsh.each do |key,val| 
      sym_hsh[key.to_sym] = val
    end
    @passed_hash = sym_hsh
    @hsh = self.defaults.merge(sym_hsh)
    @hsh.each do |key,value|
      self.send("#{key.to_s}=",value) if defaults.has_key?(key.to_sym) || self.respond_to?("#{key.to_s}=")
    end
    
    
    @additional_vars = []
  end

  def attributes
    to_h
  end

  def attributes=(hsh)
    hsh.each do |key,value|
      self.send("#{key.to_s}=",value) if defaults.has_key?(key.to_sym) || self.respond_to?("#{key.to_s}=")
    end
  end

  def additional_vars(vars)
    @additional_vars += vars
    
    vars.each do |key|
      val = hsh[key.to_sym]
      if key.to_s =~ /_(id)$/ 
        val = val.blank? ? nil : val.to_i
      end
      
      self.instance_variable_set "@#{key}",val
    end
  end

  def to_passed_hash
    to_h.slice( *@passed_hash.keys )
  end
  
  def to_h(opts={})
    self.valid? unless opts[:skip]
    hsh = {}
    
    self.instance_variables.each do |var|
      key = var.to_s.slice(1,var.length-1).to_sym
      if key && (self.defaults.has_key?(key) || @additional_vars.include?(key))
        hsh[key] = self.instance_variable_get(var)  
      end
    end
    hsh
  end
  
  def to_hash
    to_h
  end
  
  def option_to_i(opt)
    val = self.send(opt)
    self.instance_variable_set "@#{opt.to_s}",val.to_i
  end
  
  def method_missing(arg, *args)
    arg = arg.to_s
    if arg == 'hsh=' || arg == 'errors='
      #
    elsif arg[-1..-1] == "="
      raise "Undeclared HashModel variable: #{arg[0..-2]}"
    elsif self.strict?
      raise "Missing hash model method #{arg}" unless self.instance_variables.include?("@#{arg}")
      self.instance_variable_get "@#{arg}"
    else
      self.instance_variable_get "@#{arg}"
    end
  end
  
  def strict?; false; end

  def valid?
    format_data
    super
  end
  
  def format_data
   int_opts = self.class.current_integer_opts
    int_opts.each do |opt|
      val = self.send(opt)
      val = val.blank? ? nil : val.to_i
        self.instance_variable_set "@#{opt.to_s}",val
    end
    bool_opts = self.class.current_boolean_opts
    bool_opts.each do |opt|
      val = self.send(opt)
      if val.is_a?(String) # Assume we're a bool if not a val
        val  = (val == 'true' || val.to_i == 1) ? true : false
        self.instance_variable_set "@#{opt.to_s}",val
      end
    end
    float_opts = self.class.current_float_opts
    float_opts.each do |opt|
      val = self.send(opt)
      if val.is_a?(String)
        val = val.blank? ?  nil : val.to_f
        self.instance_variable_set "@#{opt.to_s}",val
      end
    end
    int_arr_opts = self.class.current_integer_array_opts
    int_arr_opts.each do |opt|
      val = self.send(opt)
      if val.is_a?(Array)
        val = val.map { |elm| elm.blank? ? nil : elm.to_i }.compact
      else
        val = []
      end
      self.instance_variable_set "@#{opt.to_s}",val
    end
  end
     
  def self.self_and_descendants_from_active_record
    [  ]
  end 
  
  def self.human_name
    self.name.underscore.titleize
  end  
  
  def self.human_attribute_name(attribute)
    attribute.to_s.humanize
  end  


  def self.current_canonical_opts; []; end
  
  def self.meta_canonical_paragraph(container_type,options ={ })
    obj = [ 'ContentMetaType',container_type,options ]
    objs = current_canonical_opts + [ obj ]
    
    class << self; self end.send(:define_method,"current_canonical_opts") do
      objs
    end  
  end

  def self.canonical_paragraph(container_type,container_field_id,options ={ })
    obj = [ 'ContentType',container_type,container_field_id,options ]
    objs = current_canonical_opts + [ obj ]
    
    class << self; self end.send(:define_method,"current_canonical_opts") do
      objs
    end
  end

  def self.run_worker(method, parameters={}, attributes={})
     DomainModelWorker.async_do_work(:class_name => self.to_s,
                                     :domain_id => DomainModel.active_domain_id,
                                     :params => parameters,
                                     :method => method,
                                     :language => Locale.language_code,
                                     :attributes => attributes,
                                     :hash_model => true
                                     )
  end

  def run_worker(method, parameters={})
    self.class.run_worker(method, parameters, self.attributes)
  end
end
