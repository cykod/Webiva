# Copyright (C) 2009 Pascal Rettig.


# Domain is a SystemModel (meaning it sits in the master Webiva database,
# not each domain's database) that represents an individiual domain on the 
# system. Any number of domains may be linked against a single database, so
# that multiple sites can share the same content.
class Domain < SystemModel 
  belongs_to :client
  
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

  def before_create #:nodoc: 
    self.inactive_message = 'Site Currently Down for Maintenance' if self.blank?
  end

  def after_save #:nodoc:
    # Clear the domain information out of any cache
    DataCache.set_domain_info(self.name,nil)
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
       # Create the database, yml files and run the initial migration
       ok  = `cd #{RAILS_ROOT};rake cms:create_domain_db DOMAIN_ID=#{self.id}`
    end
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
end
