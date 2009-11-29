# Copyright (C) 2009 Pascal Rettig.

require 'digest/sha1'

# require 'model_extension/editor_change_extension'
# require 'model_extension/file_instance_extension'

class DomainModel < ActiveRecord::Base
  self.abstract_class = true
  @@domain_db_connections = {} ## Not used in Backgroundrb
  @@active_domain = {} # Made Thread safe for Backgroundrb
  @@active_file = nil
  
#  extend ActiveSupport::Memoizable 

  include HandlerActions
  include ModelExtension::OptionsExtension
  
  cattr_accessor :logger

  def self.active_domain
    @@active_domain[Process.pid]  || {}
  end
  
  def self.active_domain_id
    (@@active_domain[Process.pid]  || {})[:id].to_s
  end
  
  def self.active_domain_name
    (@@active_domain[Process.pid]  ||{})[:name].to_s
  end
  
  def self.active_domain_db
    (@@active_domain[Process.pid]  ||{})[:database].to_s
  end
  
  def self.inspect_values
    self.object_id.to_s + ":" + @@active_domain.inspect
  end

  def self.class_name
    self.to_s
  end
  
  def update_all_attributes(atr = {})
    self.send("attributes=",atr,false)
    self.save
  end

  # use instead of belongs_to :domain_file
  def self.has_domain_file(field_name,options={})
    field = field_name.to_s.gsub(/_id$/,'')

    belongs_to field, :class_name => 'DomainFile', :foreign_key => field_name

  end

  
  def self.paginate(page,args = {})
    args = args.clone.symbolize_keys!
    window_size =args.delete(:window) || 2
    
    page_size = args.delete(:per_page).to_i
    page_size = 20 if page_size <= 0

    count_args = args.slice( :conditions, :joins, :include, :distinct, :having)
    
    if page_size.is_a?(Integer)
      
      if args[:group]
        count_by = args[:group]
        count_args[:distinct] = true
      end

      if count_by
        total_count = self.count(count_by,count_args)
      else
        total_count = self.count(count_args)
      end
      pages = (total_count.to_f / (page_size || 10)).ceil
      pages = 1 if pages < 1
      page = (page ? page.to_i : 1).clamp(1,pages)
      
      offset = (page-1) * page_size
      
      args[:offset] = offset
      args[:limit] = page_size
    else
      total_count = 0
      page = 1
      pages = 1
    end

    items = self.find(:all,args)

    [ { :pages => pages, 
        :page => page, 
        :window_size => window_size, 
        :total => total_count,
        :per_page => page_size,
        :first => offset+1,
        :last => offset + items.length
      }, items ]
    
      
  end

  def self.paginate_helper(page,count,args = {})
      window_size =args.delete(:window) || 2
      
      page_size = args.delete(:per_page).to_i
      page_size = 20 if page_size <= 0
      
      if page_size.is_a?(Integer)
	total_count = count
	pages = (total_count.to_f / (page_size || 10)).ceil
	pages = 1 if pages < 1
	page = (page ? page.to_i : 1).clamp(1,pages)
	
	offset = (page-1) * page_size
	
	offset
	page_size
      else
        page = 1
        pages = 1
      end

      { :pages => pages, :page => page, :window_size => window_size, :offset => offset, :page_size => page_size }
  end
  
  
  include WebivaValidationExtension
  include ModelExtension::EditorChangeExtension
  include ModelExtension::FileInstanceExtension
  include ModelExtension::ContentNodeExtension
  include ModelExtension::ContentCacheExtension
  
  
  def self.has_triggered_actions
    has_many :triggered_actions, :as => :trigger, :conditions => 'comitted = 1', :dependent => :destroy
    
    self.module_eval(<<-SRC)
    def run_triggered_actions(data = {},trigger_name = nil,user = nil)
      actions = trigger_name ?  self.triggered_actions.find(:all,:conditions => ['action_trigger=?',trigger_name]) :  self.triggered_actions
      actions.each do |act|
	act.perform(data,user)
      end
    end    
    SRC

  end
  
  def self.activate_domain(domain_info,environment='production',save_connection = true)
    DataCache.reset_local_cache
  
    unless domain_info.is_a?(Hash)
      if domain_info.is_a?(Integer)
      	domain_info = Domain.find_by_id(domain_info).attributes
      elsif domain_info.is_a?(String)
        domain_info = Domain.find_by_name(domain_info).attributes
      end
    end
  
    domain_info.symbolize_keys!
    
    @@active_domain[Process.pid] = domain_info
    
    file = "#{RAILS_ROOT}/config/sites/#{domain_info[:database]}.yml"
    
    self.activate_database_file(file,environment,save_connection)
    
    return true
  end
  
  def has(name)
    @extra_relations ||= {}
    return @extra_relations[name] if @extra_relations[name]
    @extra_relations[name] = name.to_s.classify.constantize.find(:first,:conditions => { "#{self.class.to_s.underscore}_id" => self.id })
  end
  
  
  def full_identifier
    "#{self.class.to_s.underscore}_#{self.id}"
  end
  
  class << self
    alias_method :connection_active_record, :connection
  end
  
  def self.connection
    @@webiva_connection ||= self.connection_active_record
  end
  
  def self.connection=(val)
    @@webiva_connection = val
  end
  
  
  def self.activate_database_file(file,environment = 'production',save_connection = true)
    if (file + environment )== @@active_file
      return 
    end
    
    pid = Process.pid
    
    if save_connection && @@domain_db_connections[pid] && @@domain_db_connections[pid][file] && @@domain_db_connections[pid][file][environment]
      DomainModel.connection = @@domain_db_connections[pid][file][environment]
      begin
        if !DomainModel.connection.active?
          DomainModel.connection.reconnect!
        end
      rescue Mysql::Error
        DomainModel.connection.reconnect!
      end
    else
      @@domain_db_connections[pid] ||= {}
      @@domain_db_connections[pid][file] ||= {}
      # If domain doesn't exist anymore
      # return an error
      begin
        db_config_file = YAML.load_file(file)
      rescue 
        return false
      end
      db_config = db_config_file[ environment ]

      # Modify the base connection for AR Base if we're testing
      ActiveRecord::Base.establish_connection(db_config) if RAILS_ENV == 'test'
      
      @@webiva_connection = nil
      DomainModel.establish_connection(db_config)
      # DomainModel.connection.reconnect!
      
      # Only save connection if variable set (in single threaded environment)
      if save_connection
        @@domain_db_connections[pid][file][environment] = DomainModel.connection
      end
    end
    @@active_file = file + environment
    
    @@webiva_connection = nil if RAILS_ENV == 'test' # Clear out the webiva connection in test
    return true
  end
  
  def self.run_worker(class_name,entry_id,method,parameters = {})
      worker_key = MiddleMan.new_worker(
        :class => :domain_model_worker,
				:args => { :class_name => class_name,
					    :entry_id => entry_id,
					    :domain_id => DomainModel.active_domain_id,
					    :params => parameters,
					    :method => method,
              :language => Locale.language_code  }
					  )

      worker_key  
  end
  
  def run_worker(method,parameters = {})
    self.class.run_worker(self.class.to_s,self.id,method,parameters)
  end
  
  def self.worker_results(key)
    Cache.get("domain_worker:" + key.to_s)
  end 
  
  public
  
  def self.generate_hash
     Digest::SHA1.hexdigest(Time.now.to_i.to_s + rand(1e100).to_s)
  end

  def self.find_select_options(val=:all,opts={})
    self.find(val,opts).collect do |itm|
      [ itm.name, itm.id ]
    end
  end

  def self.select_options_with_nil(name=nil,opts={})
    obj_name = name || self.to_s.underscore.humanize
    [["--Select %s--" / obj_name,nil ]] + self.select_options(opts)
  end
  
  def self.select_options(opts={})
    self.find(:all,opts).collect do |itm|
      [ itm.name, itm.id ]
    end
  end
  
  def self.find_options(val=:all,opts={})
    self.find_select_options(val,opts)
  end
  

  # Resolve an argument that may be a Proc, a Symbol or Blank (use default attribute)
  def resolve_argument(arg,default = :name)
   if arg.is_a?(Proc) 
      arg.call(self)
   elsif arg.is_a?(String)
      arg
   elsif !arg.blank?
      self.send(arg.to_sym)
   elsif default
      self.send(default)
   end
  end       
  
 # %%VARIABLE%%
 # %%VARIABLE{Happy}[[ This is what should be there instead of just %s ]]%%
 # %%VARIABLE{!Happy}[[ This is what should be when we're not happy ]]%%
 # %%VARIABLE{!Happy,Sad,Friendly}[[ This is what should be when we're not happy, ARE sad, or ARE Friendly]]%%
 # %%VARIABLE[[Replacement text]]%%
 def self.variable_replace(txt,vars = {})
   vars = vars.symbolize_keys
    txt.gsub(/\%\%(\w+)\%\%/) do |mtch|
      var_name =$1.downcase.to_sym
      vars[var_name] ? vars[var_name] : ''
    end
  end  
  
 def variable_replace(txt,vars = {})
   vars = vars.symbolize_keys
   txt.gsub(/\%\%(\w+)\%\%/) do |mtch|
     var_name =$1.downcase.to_sym
#     raise var_name.to_s + vars[var_name].inspect
     vars[var_name] ? (vars[var_name].is_a?(Proc) ? vars[var_name].call(self,var_name) : vars[var_name]) : ''
   end
  end
  
  def set_through_collection(collection,foreign_key,ids)
    # get id's into the right format => array of ints

    ids ||= []
    ids = ids.find_all { |elm| !elm.blank? }.collect { |elm| elm.to_i }
    
    # get the current collection of elements
    current_collection = self.send(collection,true)
    
    # Remove the elements no longer in the ids array
    current_collection.find_all { |cur_elm| !ids.include?(cur_elm.send(foreign_key)) }.each { |elm| elm.destroy }
    
    # find the elements to add
    ids.each do |cur_id|
      elm = current_collection.detect { |elm| elm.send(foreign_key) == cur_id }
      current_collection.create(foreign_key => cur_id) unless elm
    end
  end

  def set_through_collection_with_attributes(collection,foreign_key,data)
    # get id's into the right format => array of ints
    data ||= []
    ids ||= []
    data = data.find_all { |elm| !elm.blank? }.collect do |elm|
      if !elm[foreign_key].blank?
        elm[foreign_key] = elm[foreign_key].to_i
        ids << elm[foreign_key]
        elm
      else
        nil
      end
    end.compact
    
    # get the current collection of elements
    current_collection = self.send(collection,true)
    
    # Remove the elements no longer in the ids array
    current_collection.find_all { |cur_elm| !ids.include?(cur_elm.send(foreign_key)) }.each { |elm| elm.destroy }
    
    # find the elements to add
    data.each do |data_elem|
      cur_id = data_elem[foreign_key]
      elm = current_collection.detect { |elm| elm.send(foreign_key) == cur_id }
      if elm
        elm.update_attributes(data_elem)
      else
        current_collection.create(data_elem) 
      end
    end
  end

  def through_connection_cache(collection,data)
    if(data)
      col = self.send(collection.to_sym)
      data.map { |elm| col.build(elm) }
    else
      self.send(collection.to_sym)
    end
  end

  
 

  
  
#  alias_method :save_active_record, :save
#  
#  def save(validate=true)
#    post_handlers(self,:pre_save)
#    if save_active_record(validate)
#        post_handlers(self,:post_save)
#    end
#  end
#  
#  alias_method :destroy_active_record, :destroy
#  
#  def destroy
#    post_handlers(self,:pre_destroy)
#    if destroy_active_record
#        post_handlers(self,:post_destroy)
#    end
#  end
  
  def post_handlers(record,action)
    DomainModel.get_handlers(:model,record.class.to_s.underscore.to_sym).each do |handler|
      if handler[1] && handler[1][:actions] && handler[1][:actions].include?(action)
        hndl = handler[0].constantize.new(handler)
        hndl.send(action,record)
      end
    end
  end  

  
  
 class CallbackHandlers

    def before_save(record)
      handlers(record,:before_save)
      return true
    end
    
    def after_save(record)
      handlers(record,:after_save)
      return true
    end
    
    def before_create(record)
      handlers(record,:before_create)
      return true
    end
    
    def after_create(record)
      handlers(record,:after_create)
      return true
    end
    
    def before_update(record)
      handlers(record,:before_update)
      return true
    end
    
    def after_update(record)
      handlers(record,:after_update)
      return true
    end

    def before_destroy(record)
      handlers(record,:before_destroy)
      return true
    end

    def after_destroy(record)
      handlers(record,:after_destroy)
      return true
    end
    
    def handlers(record,action)
      DomainModel.get_handlers(:model,record.class.to_s.underscore.to_sym).each do |handler|
        if handler[1] && handler[1][:actions] && handler[1][:actions].include?(action)
          hndl = handler[0].constantize.new(handler)
          hndl.send(action,record)
        end
      end
    end
  end  
  before_create DomainModel::CallbackHandlers.new
  before_destroy DomainModel::CallbackHandlers.new
  after_create DomainModel::CallbackHandlers.new
  before_save DomainModel::CallbackHandlers.new
  after_save DomainModel::CallbackHandlers.new
  before_update  DomainModel::CallbackHandlers.new
  after_update  DomainModel::CallbackHandlers.new
  after_destroy   DomainModel::CallbackHandlers.new
  
  
  
   
  def self.has_content_tags
    has_many :content_tag_tags, :as => :content, :include => :content_tag
    has_many :content_tags, :through => :content_tag_tags, :order => 'content_tags.name'
    after_save :tag_cache_after_save
    include ContentTagFunctionality
  end
  
  module ContentTagFunctionality
  
    module ClassMethods
    
      def tag_cloud(sizes=[])
        ContentTag.get_tag_cloud(self.to_s,sizes)
      end
      
      def tag_options
        ContentTag.find_select_options(:all,:conditions => { :content_type =>  self.to_s })
      end
      
    end
    
    def tags_array
      if @tag_name_cache.is_a?(Array)
        @tag_name_cache
      else
        self.content_tags.collect(&:name)
      end
    end
  
    def tag_names
      self.tags_array.join(", ")
    end
    
    def tag_name_helper(values)
      values.split(",").collect { |nm| nm.strip.downcase.capitalize }.find_all { |tg| !tg.blank? }
    end
    
    def tag_names=(values)
      tags = tag_name_helper(values)
      
      @tag_name_cache = tags
    end
    
    def add_tags(values)
      tags = tag_name_helper(values)
      
      @tag_name_cache = tags + tags_array
      tag_cache_after_save
    end
    
    def remove_tags(values)
      tags_del = tag_name_helper(values)
      
      @tag_name_cache = tags_array.find_all() { |tg| !tags_del.include?(tg) }
      tag_cache_after_save
    end
    
    def tag_cache_after_save
      if @tag_name_cache.is_a?(Array)
        @tag_name_cache.uniq!
        tags = self.content_tag_tags
        
        @existing_tags = []
        tags.each do |tg|
          if tg.content_tag && @tag_name_cache.include?(tg.content_tag.name)
            @existing_tags << tg.content_tag.name
          else
            tg.destroy
            tg.content_tag.destroy if(tg.content_tag && tg.content_tag.content_tag_tags.size == 0)
          end
        end
        
        @tag_name_cache.each do |tag_name|
          unless @existing_tags.include?(tag_name)
              tg = ContentTag.get_tag(self.class.to_s,tag_name)
              self.content_tag_tags.create(:content_tag => tg)
          end
        end
      end
      
      @tag_name_cache = nil
    end
    
  
    
    def self.append_features(base) #:nodoc:
      super
      base.extend(ClassMethods)
    end
  
  end
   def generate_url(field,value)
     permalink_try_partial = value.to_s.downcase.gsub(/[ _]+/,"-").gsub(/[^a-z+0-9\-]/,"")
     idx = 2
     permalink_try = permalink_try_partial[0..60]
     
     while(self.class.send("find_by_#{field}",permalink_try,:conditions => ['id != ?',self.id || 0] ))
       permalink_try = permalink_try_partial + '-' + idx.to_s
       idx += 1
     end
     
     self.send("#{field}=",permalink_try)
  end
  
  def expire_site
    DataCache.expire_container('SiteNode')
    DataCache.expire_container('Handlers')
    DataCache.expire_container('SiteNodeModifier')
    DataCache.expire_container('Modules')
    DataCache.expire_content
  end
    
end
