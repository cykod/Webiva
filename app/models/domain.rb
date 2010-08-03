# Copyright (C) 2009 Pascal Rettig.


# Domain is a SystemModel (meaning it sits in the master Webiva database,
# not each domain's database) that represents an individiual domain on the 
# system. Any number of domains may be linked against a single database, so
# that multiple sites can share the same content.
class Domain < SystemModel 
  belongs_to :client

  belongs_to :domain_database

  has_many :domain_modules, :dependent => :destroy
  
  
  has_many :domain_routes, :dependent => :destroy
  
  has_many :active_modules, :class_name=> 'DomainModule',
            :conditions => 'status = "active"'
  
  has_many :email_aliases, :dependent => :destroy
  has_many :email_mailboxes, :dependent => :destroy
  has_many :email_transports, :dependent => :destroy
  
  #  acts_as_authorizable

  validates_presence_of :name
  validates_uniqueness_of :name
  
  validates_format_of :name, :with => /^([a-zA-Z0-9\.\-]+?)\.([a-zA-Z]+)$/,
                      :message => ' is not a valid domain '

  validates_presence_of :client_id
  validates_presence_of :domain_type
  validates_inclusion_of :domain_type, :in => %w(domain redirect)

  def before_create #:nodoc: 
    self.inactive_message = 'Site Currently Down for Maintenance' if self.inactive_message.blank?
  end

  def validate
    self.errors.add(:client_id, 'is missing') unless self.client
    self.errors.add(:max_file_storage, 'is too large') if self.max_file_storage && self.client && self.max_file_storage > self.client.available_file_storage(self.domain_database)
    self.errors.add(:domain_database_id, 'is invalid') if self.domain_database && self.domain_database.client_id != self.client_id
  end

  def after_save #:nodoc:
    # Clear the domain information out of any cache
    if self.domain_database
      self.domain_database.save
    elsif @max_file_storage
      self.create_domain_database :client_id => self.client_id, :name => self.database, :max_file_storage => @max_file_storage
      @max_file_storage = nil
      self.save
    else
      DataCache.set_domain_info(self.name,nil)
    end
  end

  def max_file_storage
    self.domain_database ? self.domain_database.max_file_storage : @max_file_storage
  end

  def max_file_storage=(max)
    if self.domain_database
      self.domain_database.max_file_storage = max.to_i
    else
      @max_file_storage = max.to_i
    end
  end

  def status_display
    self.status.capitalize.t
  end
  
  def domain_type_display
    self.domain_type.capitalize.t
  end

  # Finds all the users of a certain client
  def self.get_client_domains(client_id,*args) 
    
    Domain.find_merged_push(args,:all, :conditions => ['client_id = ? ',client_id],
                                 :order => "name")

  end
 
  # Returns a list of active modules
  def get_active_modules
    self.domain_modules.find(:all, :conditions => 'status = "active"', :order => 'name')
  end


  def initialize_database(params = {}) #:nodoc:
    if (self.status == 'setup' || self.status == 'initializing') && self.domain_type == 'domain' && self.database.to_s.empty?
       self.status = 'initializing'
       self.save
       initializer = " INITIALIZER=#{params[:initializer]}" if params[:initializer]
       # Create the database, yml files and run the initial migration
       ok  = `cd #{RAILS_ROOT};rake cms:create_domain_db DOMAIN_ID=#{self.id}#{initializer}`
    end
  end

  def update_module_availability(mod,available)
    entry = self.domain_modules.find_by_name(mod) || self.domain_modules.build(:name => mod)
    entry.access = available ? 'available' : 'unavailable'
    entry.save
  end

  def self.current_site_domains
    self.find_site_domains(Configuration.domain_info.database) 
  end

  # Return a list of all domains on a given database
  def self.find_site_domains(database_name)
    self.find(:all,:conditions => { :database => database_name }, :order => 'name')
  end

  # Return a single domain on a given database
  def self.find_site_domain(domain_id,database_name)
    self.find(domain_id,:conditions => { :database => database_name })
  end

  # Return the name of the version active on this domain
  def version_name
    if  version
       version.name
    else
     '**Error: No Active Version**'.t
    end
  end

  # Returns the active SiteVersion for this domain
  def version
    @version ||= SiteVersion.find_by_id(self.site_version_id)
  end

  def destroy_domain #:nodoc:
    dmns = Domain.find(:all,:conditions => { :database => self.database })
    if dmns.length > 1
      self.destroy
    end
  end

  # Make this the primary domain
  def set_primary
    Domain.update_all('`primary`=0',['`database`=? AND id!=?',self.database,self.id])
    update_attribute(:primary,true)
  end

  # Populates the active Domain database with the 
  # required initial data
  def self.initial_domain_data
    UserClass.create_built_in_classes
    UserClass.add_default_editor_permissions
    SiteVersion.default.root
    SiteTemplate.create_default_template
    Editor::AdminController.content_node_type_generate
    Dashboard::CoreWidget.add_default_widgets
  end

  def database_file
    "#{RAILS_ROOT}/config/sites/#{self.database}.yml"
  end

  def get_info
    info = self.attributes.symbolize_keys
    if self.domain_database
      info[:domain_database] = self.domain_database.attributes.symbolize_keys
    else
      info[:domain_database] = {:client_id => self.client_id, :name => self.database, :options => YAML.load_file(self.database_file), :max_client_users => nil, :max_file_storage => nil, :config => nil}
    end

    info
  end

  def save_database_file
    if File.exists?(self.database_file)
      if self.domain_database
        self.domain_database.update_attributes :options => YAML.load_file(self.database_file)
      else
        self.domain_database = DomainDatabase.find_by_name(self.database)
        unless self.domain_database
          self.create_domain_database :client_id => self.client_id, :name => self.database, :options => YAML.load_file(self.database_file), :max_file_storage => (self.max_file_storage || DomainDatabase::DEFAULT_MAX_FILE_STORAGE)
        end
        self.save
      end
    elsif self.domain_database.nil?
      self.domain_database = DomainDatabase.find_by_name(self.database)
      self.save
    end
  end

  def self.each(env='production', ids=nil)
    domains = Domain.find(:all, :conditions => 'domain_type = "domain" AND `database` != "" AND `status`="initialized"').collect { |dmn| dmn.get_info }.uniq
    domains.each do |dmn|
      ActiveRecord::Base.establish_connection(dmn[:domain_database][:options][env])
      DomainModel.activate_domain(dmn, env)
      yield dmn
    end
  end

  def execute(environment='production')
    active_domain_id = DomainModel.active_domain_id
    active_domain = DomainModel.active_domain
    DomainModel.activate_domain(self.get_info, environment) unless active_domain_id == self.id
    yield
    DomainModel.activate_domain(active_domain, environment) unless active_domain_id == self.id || active_domain_id.blank?
  end
end
