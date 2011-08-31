# Copyright (C) 2009 Pascal Rettig.

require 'digest/sha1'

# Master ActiveRecord::Base class for all per-domain tables
class DomainModel < ActiveRecord::Base
  self.abstract_class = true
  @@active_domain = {} # Made Thread safe for Backgroundrb
  
  include HandlerActions
  include ModelExtension::OptionsExtension

  @@mutex = Mutex.new
  
  cattr_accessor :logger

  def self.process_id
    Thread.current.object_id
  end

  # Returns the active domain information hash
  def self.active_domain
    @@active_domain[process_id]  || {}
  end
  
  # Returns the active domain id from the Domain table
  def self.active_domain_id
    (@@active_domain[process_id]  || {})[:id].to_s
  end
  
  # Returns the name of the active domain
  def self.active_domain_name
    (@@active_domain[process_id]  ||{})[:name].to_s
  end
  
  # Returns the database of the active domain
  def self.active_domain_db
    (@@active_domain[process_id]  ||{})[:database].to_s
  end
  
  def self.site_version_id
    (@@active_domain[process_id]||{})[:site_version_id].to_s
  end
  # Returns the name of the class
  #  (overridden in ContentModelType where self.to_s doesn't work)
  def self.class_name
    self.to_s
  end
  
  # Allow update to all attributes via a Hash, even 
  # protected attributes
  def update_all_attributes(atr = {})
    self.send("attributes=",atr,false)
    self.save
  end

  # Creates a belongs_to relationship with DomainFile
  # and adds DomainFileInstance support
  #
  # Use instead of belongs_to :domain_file
  def self.has_domain_file(field_name,options={})
    field = options[:relation] || field_name.to_s.gsub(/_id$/,'')

    belongs_to field.to_sym, :class_name => 'DomainFile', :foreign_key => options[:foreign_key] || field_name
    domain_file_column(field_name)
  end

  def self.has_end_user(field_name,options={})
    field = options[:relation] || field_name.to_s.gsub(/_id$/,'')

    belongs_to field.to_sym, :class_name => 'EndUser', :foreign_key => options[:foreign_key] || field_name
    after_save_update_end_user_name(field, options[:name_column]) if options[:name_column]
  end

  # Used to paginate a list of entries, returns a pagination information hash
  # and a list of entries
  # 
  # Usage (Using BlogPost as an example)
  #    
  #   @pages, @posts = BlogPost.paginate(params[:page],:per_page => 10,:conditions => ...)
  #
  # Where @pages is a Hash with the following keys:
  #
  # [:pages]
  #   total number of pages
  # [:page]
  #   current page
  # [:window_size] 
  #   size of the pagination window
  # [:total]
  #  total number of entries (on all pages)
  # [:per_page]
  #  number of entries per page we are showing
  # [:first]
  #  index of the first entry returned
  # [:last]
  #  index of the last entry returned
  # [:count]
  #  number of entries returned
  # 
  # === Options
  # (All regular find options are accepted)
  # 
  # [:per_page] 
  #   Number of entries per page
  # [:window_size]
  #   Size of page window - passed through to pagination hash (used by CmsHelper#admin_pagination for example
  def self.paginate(page,args = {},scope_by = nil)
    scope_by ||= self
    page = page.to_i
    page = 1 if page < 1
    args = args.clone.symbolize_keys!
    window_size =args.delete(:window) || 2
    
    page_size = args.delete(:per_page).to_i
    page_size = 20 if page_size <= 0

    count_args = args.slice( :conditions, :joins, :include, :distinct, :having)

    if args.delete(:large)
      offset = args[:offset] = page_size * (page-1)
      args[:limit] = page_size + 1

      items = self.find(:all,args)


      if items.length == page_size + 1
        pages = page + 1
        total = pages * page_size
        items = items[0..page_size-1]
      else
        pages = page
        total = pages * page_size
      end
    elsif page_size.is_a?(Integer)
      
      if args[:group]
        count_by = args[:group]
        count_args[:distinct] = true
      end

      if count_by
        total_count = scope_by.count(count_by,count_args)
      else
        total_count = scope_by.count(count_args)
      end
      pages = (total_count.to_f / (page_size || 10)).ceil
      pages = 1 if pages < 1
      page = (page ? page.to_i : 1).clamp(1,pages)
      
      offset = (page-1) * page_size
      
      args[:offset] = offset
      args[:limit] = page_size

      items = scope_by.find(:all,args)
    else
      offset = 0
      total_count = 0
      page = 1
      pages = 1

      items = scope_by.find(:all,args)
    end

   
    [ { :pages => pages, 
        :page => page, 
        :window_size => window_size, 
        :total => total_count,
        :per_page => page_size,
        :first => offset+1,
        :last => offset + items.length,
        :count => items.length
      }, items ]
    
      
  end

  include WebivaValidationExtension
  include ModelExtension::EditorChangeExtension
  include ModelExtension::FileInstanceExtension
  include ModelExtension::ContentNodeExtension
  include ModelExtension::ContentCacheExtension
  include ModelExtension::EndUserExtension
  
  # Adds support for triggered actions to this object
  # 
  # adds a method called run_triggered_actions(data,trigger_name,user)
  # which will run all the triggered actions associated with this object
  def self.has_triggered_actions
    has_many :triggered_actions, :as => :trigger, :conditions => 'comitted = 1', :dependent => :destroy
  end

  def run_triggered_actions(data = {},trigger_name = nil,user = nil,session = nil)
    if (trigger_name.to_s == 'view' && self.view_action_count > 0) || (trigger_name.to_s != 'view' && self.update_action_count > 0)
      actions = trigger_name ?  self.triggered_actions.find(:all,:conditions => ['action_trigger=?',trigger_name]) :  self.triggered_actions
      actions.each do |act|
        act.perform(data,user,session)
      end
    end
  end    


  # Activates a specific domain as the active domain 
  # 
  # This method can be used to access domain models via the Rails console
  #     
  #    $ ./script/console
  #    Loading development environment (Rails 2.3.4)
  #    >> DomainModel.activate_domain(1)
  #    => true
  #    >> EndUser.find(:first,:email => ...
  #
  # This would activate the domain with id 1 from the Domain table
  def self.activate_domain(domain_info,environment='production',save_connection = true)
    DataCache.reset_local_cache

    if domain_info.is_a?(Hash) && domain_info[:domain_database].nil?
      raise 'Missing domain_database, use get_info instead of attributes' unless Rails.env == 'production'
      domain_info = domain_info[:id]
    end

    unless domain_info.is_a?(Hash)
      if domain_info.is_a?(Integer)
      	domain_info = Domain.find_by_id(domain_info).get_info
      elsif domain_info.is_a?(String)
        domain_info = Domain.find_by_name(domain_info).get_info
      end
    end
  
    domain_info.symbolize_keys!
    
    @@active_domain[process_id] = domain_info
    
    self.activate_database(domain_info,environment,save_connection)
    
    return true
  end
  

  # Used to access and memoize a 1-way relationship
  def has(name)
    @extra_relations ||= {}
    return @extra_relations[name] if @extra_relations[name]
    @extra_relations[name] = name.to_s.classify.constantize.find(:first,:conditions => { "#{self.class.to_s.underscore}_id" => self.id })
  end
  
  
  # Returns a full unique identifier for a class
  def full_identifier
    "#{self.class.to_s.underscore}_#{self.id}"
  end
  
  class << self
    alias_method :connection_active_record, :connection # :nodoc:
  end

  @@database_connection_pools = {}
  def self.connection
    if  @@database_connection_pools[self.process_id]
       @@database_connection_pools[self.process_id].connection
    else
      connection_active_record
    end
  end
  
  def self.activate_database_file(file,environment = 'production',save_connection = true)
    
    delegate_class_name = File.basename(file,'.yml').classify

    if !Object.const_defined?(delegate_class_name)
      begin
        db_config_file = YAML.load_file(file)
      rescue 
        return false
      end
      db_config = db_config_file[ environment ]

      cls = Object.const_set(delegate_class_name.to_s, Class.new(ActiveRecord::Base))
      cls.abstract_class = true
      cls.establish_connection(db_config)

      @@database_connection_pools[self.process_id] = cls
      return true
    else
      @@database_connection_pools[self.process_id] = delegate_class_name.constantize
      @@mutex.synchronize do 

        @@database_connection_pools[self.process_id].connection.verify!
      end

      return true
    end
  end
  
  def self.activate_database(domain_info,environment = 'production',save_connection = true)
    
    delegate_class_name = (domain_info[:database] + "_" + environment).classify

    if !Object.const_defined?(delegate_class_name)
      begin
        db_config_file = domain_info[:domain_database][:options]
      rescue 
        return false
      end
      db_config = db_config_file[ environment ]

      cls = Object.const_set(delegate_class_name.to_s, Class.new(ActiveRecord::Base))
      cls.abstract_class = true
      db_config['persistent'] = false
      cls.establish_connection(db_config)

      @@database_connection_pools[self.process_id] = cls
      return true
    else
      @@database_connection_pools[self.process_id] = delegate_class_name.constantize
      @@mutex.synchronize do 

        @@database_connection_pools[self.process_id].connection.verify!
      end

      return true
    end
  end
  
  # Run a worker on a specific DomainModel
  # see DomainModel#run_worker if you already have the ActiveRecord object
  def self.run_worker(class_name,entry_id,method,parameters = {})
     DomainModelWorker.async_do_work(
                                     :class_name => class_name,
                                     :entry_id => entry_id,
                                     :domain_id => DomainModel.active_domain_id,
                                     :params => parameters,
                                     :method => method,
                                     :language => Locale.language_code  
					  )

  end

  def self.run_class_worker(method,parameters = { })
    self.run_worker(self.to_s,nil,method,parameters)
  end
  
  # Runs a background process worker that will 
  # issue a find command on this object and then run the specified method
  def run_worker(method,parameters = {}) 
    self.class.run_worker(self.class.to_s,self.id,method,parameters)
  end
  
  # Fetches results out of memcached for a specific worker key
  # returns from run_worker
  def self.worker_results(key)
    Workling.return.get(key)
  end 

  # Generates a random hexdigest hash
  def self.generate_hash
     Digest::SHA1.hexdigest(Time.now.to_i.to_s + rand(1e100).to_s)
  end

  def self.hexdigest(val)
    Digest::SHA1.hexdigest(val)[0..63]
  end

  # Generates a hexdigest hash on a hash
  # by turning the hash into an array, sorting the keys
  # and hashing the resultant array - allows Hash's with the same
  # keys and values to generate consistent Hash's
  # and will sort upto two hashes deep
  def self.hash_hash(hsh)
    arr = hsh.to_a.sort { |a,b| a[0].to_s<=>b[0].to_s }
    arr.map! { |elm| elm[1].is_a?(Hash) ? [elm[0],elm[1].to_a.sort { |a,b| a[0].to_s<=>b[0].to_s } ] : elm }
    Digest::SHA1.hexdigest(arr.to_s)[0..63]
  end

  # Deprecated in favor of select_options or select_options_with_nil
  def self.find_select_options(val=:all,opts={}) #:nodoc:
    self.find(val,opts).collect do |itm|
      [ itm.name, itm.id ]
    end
  end

  # Same as DomainModel#self.select_options execpt adds an initial
  # nil valued option that defaults to the humanized class domain.
  #
  # For Example: BlogPost.select_options_with_nil would return
  # an array of all BlogPosts names and ids with the first element set to:
  # [ "--Select Blog post--",nil ]
  def self.select_options_with_nil(name=nil,opts={})
    obj_name = name || self.to_s.underscore.humanize
    [["--Select %s--" / obj_name,nil ]] + self.select_options(opts)
  end
  
  # Returns a Array of select or radio_buttons friendly options
  # using the objects name attribute and id
  def self.select_options(opts={})
    self.find(:all,opts).collect do |itm|
      [ itm.name, itm.id ]
    end
  end
  
  # Deprecated in favor of select_options
  def self.find_options(val=:all,opts={}) #:nodoc:
    self.find_select_options(val,opts)
  end
  

  # Resolve an argument that may be a Proc, a String, a Symbol or Blank (use default attribute)
  def resolve_argument(arg,default = :name)
   if arg.is_a?(Proc) 
      arg.call(self)
   elsif arg.is_a?(String) || arg.is_a?(Fixnum)
      arg
   elsif !arg.blank?
      self.send(arg.to_sym)
   elsif default
      self.send(default)
   end
  end       

  # Returns the models attributes plus any additional attributes.
  # for example: EndUser triggered_attributes { self.attributes.merge( :name => self.name ) }
  def triggered_attributes; self.attributes; end

 # Does variable replacement of strings surrounded by two percent signs
 # for example: %%VARIABLE%% with elements from the vars hash
 #
 def self.variable_replace(txt,vars = {})
   vars = vars.symbolize_keys
    txt.gsub(/\%\%(\w+)\%\%/) do |mtch|
      var_name =$1.downcase.to_sym
      vars[var_name] ? vars[var_name] : ''
    end
  end  
  
 # Does variable replacement of strings surrounded by two percent signs
 # for example: %%VARIABLE%% with elements from the
 #
 # Same as the class level method except for support of Proc's in vars that are 
 # evaluated with the current object as a parameter
 # 
 # TODO:
 # %%VARIABLE{Happy}[[ This is what should be there instead of just %s ]]%%
 # %%VARIABLE{!Happy}[[ This is what should be when we're not happy ]]%%
 # %%VARIABLE{!Happy,Sad,Friendly}[[ This is what should be when we're not happy, ARE sad, or ARE Friendly]]%%
 # %%VARIABLE[[Replacement text]]%%
 def variable_replace(txt,vars = {})
   vars = vars.symbolize_keys
   txt.gsub(/\%\%(\w+)\%\%/) do |mtch|
     var_name =$1.downcase.to_sym
     vars[var_name] ? (vars[var_name].is_a?(Proc) ? vars[var_name].call(self,var_name) : vars[var_name]) : ''
   end
  end
  
 # Deprecated in favor of built in nested_attribute support
 def set_through_collection(collection,foreign_key,ids) #:nodoc:
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

 # Deprecated in favor of built in  nested_attribute support
 def set_through_collection_with_attributes(collection,foreign_key,data) #:nodoc:
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
     elm = current_collection.detect { |elm| elm.send(foreign_key) == cur_id.to_i }
     if elm
       len =  self.send(collection,true).length
       elm.update_attributes(data_elem)
     else
       current_collection.create(data_elem) 
     end
   end
 end

 # Deprecated in favor of built in nested attribute support
 def through_connection_cache(collection,data) #:nodoc:
   if(data)
     col = self.send(collection.to_sym)
     data.map { |elm| col.new(elm) }
   else
     self.send(collection.to_sym)
   end
 end

 
  alias_method :save_active_record, :save # :nodoc:
  
  def save(validate=true) #:nodoc:
    post_handlers(self,:pre_save)
    if save_active_record(validate)
        post_handlers(self,:post_save)
    end
  end
  
  alias_method :destroy_active_record, :destroy # :nodoc:
  
  def destroy #:nodoc:
    post_handlers(self,:pre_destroy)
    if destroy_active_record
        post_handlers(self,:post_destroy)
    end
  end
  
  def post_handlers(record,action) #:nodoc:
    DomainModel.get_handlers(:model,record.class.to_s.underscore.to_sym).each do |handler|
      if handler[1] && handler[1][:actions] && handler[1][:actions].include?(action)
        hndl = handler[0].constantize.new(handler)
        hndl.send(action,record)
      end
    end
  end  

  
  
 class CallbackHandlers #:nodoc:all

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
  
  def self.get_content_description
    self.to_s.titleize
  end
  
   
  # Adds content tag support to a model
  # includes ContentTagFunctionality methods into the class
  def self.has_content_tags
    has_many :content_tag_tags, :foreign_key => :content_id, :include => :content_tag, :dependent => :delete_all, :conditions => "content_tag_tags.content_type='" + self.to_s + "'"
    has_many :content_tags, :through => :content_tag_tags, :order => 'content_tags.name'
    after_save :tag_cache_after_save
    include ContentTagFunctionality
  end
  
  # Instance Methods added via DomainModel#has_content_tags
  module ContentTagFunctionality 
  
    # Class methods added via DomainModel#has_content_tags
    module ClassMethods 
    
      # Returns a tag cloud for this class
      def tag_cloud(sizes=[])
        ContentTag.get_tag_cloud(self.to_s,sizes)
      end
      
      # Returns a list of existing tags for this class
      def tag_options
        ContentTag.find_select_options(:all,:conditions => { :content_type =>  self.to_s })
      end
      
    end
    
    # Returns an array of tag names this object is tagged with
    def tags_array
      if @tag_name_cache.is_a?(Array)
        @tag_name_cache
      else
        self.content_tags.collect(&:name)
      end
    end
  
    # returns a string fo tag names this object is tagged with
    def tag_names
      self.tags_array.join(", ")
    end
    
    def tag_name_helper(values) #:nodoc:
      values.split(",").collect { |nm| nm.strip.downcase.capitalize }.find_all { |tg| !tg.blank? }
    end
    
    # sets the tags on this object from a comma separated string
    # current tags not appearing in values string will be removed.
    # Note: tags are not saved until after the object is saved
    def tag_names=(values)
      tags = tag_name_helper(values)
      
      @tag_name_cache = tags
    end
    
    # adds tags immediately to this object from a comma separated string 
    def add_tags(values)
      tags = tag_name_helper(values)
      
      @tag_name_cache = tags + tags_array
      tag_cache_after_save
    end
    
    # removes tags immediately from this object from a comma separated string
    def remove_tags(values)
      tags_del = tag_name_helper(values)
      
      @tag_name_cache = tags_array.find_all() { |tg| !tags_del.include?(tg) }
      tag_cache_after_save
    end
    
    def tag_cache_after_save #:nodoc:
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
            # Be explicit about the content_type for Content models (which don't have a real class name)
            self.content_tag_tags.create(:content_tag => tg,:content_type => self.class.to_s)
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

  # Generats a url-friendly string from value and assigns it to field if field is blank
  # if the field is not blank, returns the value
  def generate_url(field,value)
    permalink_try_partial = value.to_s.mb_chars.normalize(:kd).to_s.downcase.gsub(/[ _]+/,"-").gsub(/[^a-z+0-9\-]/,"")
    idx = 2
    permalink_try = permalink_try_partial[0..60]
    
    if !field.blank?
      while(self.class.send("find_by_#{field}",permalink_try,:conditions => ['id != ?',self.id || 0] ))
        permalink_try = permalink_try_partial + '-' + idx.to_s
        idx += 1
      end
      self.send("#{field}=",permalink_try)
    else
      permalink_try
    end
  end

  # Put something into the remote cache from a delayed worker
  def self.remote_cache_put(args,result)
     now = Time.now
     DataCache.put_remote(args[:remote_type],args[:remote_target],args[:display_string],[ result ,now + args[:expiration].to_i.seconds])
     DataCache.expire_content(args[:remote_type],args[:remote_target])
  end
  

  def self.expire_site
    DataCache.expire_container('SiteNode')
    DataCache.expire_container('Handlers')
    DataCache.expire_container('SiteNodeModifier')
    DataCache.expire_container('Modules')
    DataCache.expire_content
    DataCache.reset_local_cache
  end
  # Expires the entire website from the cache
  def expire_site
    self.class.expire_site
  end
   

  # http://gist.github.com/76868
  # Need an after_commit for post-transaction actions
  def save_with_after_commit(*args) #:nodoc:
    previous_new_record = new_record?
    if result = save_without_after_commit(*args)
      callback(:after_commit)
      callback(:after_commit_on_create) if previous_new_record
    end
    result
  end
  
  def save_with_after_commit!(*args)#:nodoc:
    previous_new_record = new_record?
    if result = save_without_after_commit!(*args)
      callback(:after_commit)
      callback(:after_commit_on_create) if previous_new_record
    end
    result
  end
 
  alias_method_chain :save, :after_commit 
  alias_method_chain :save!, :after_commit
  define_callbacks :after_commit, :after_commit_on_create
end
