# Copyright (C) 2009 Pascal Rettig.

# Defines User-configurable domain specific configuration options
class Configuration < DomainModel

  serialize :options
	
  # Retrieve a configuration value by key from the cache or the database
  # will create the key if it doesn't exist
  def self.get(key = 'domain',default_value = {})
    val = DataCache.get_cached_container("Config",key)
    return val if val 

    val = self.find_by_config_key(key.to_s) || self.create(:config_key => key.to_s, :options => default_value)
    DataCache.put_container("Config",key,val.options)
    val.options
  end

  # Puts a configuration value into the database and update the cache
  def self.put(key,value)
    entry = self.find_by_config_key(key.to_s) || Configuration.new(:config_key => key.to_s)
    entry.options = value
    entry.save
    DataCache.put_cached_container("Config",key,value)
    value
  end
  
  # Retrieve an entire entry row directly the database and update the cached value
  def self.retrieve(key,default_value = {})
    val = self.find_by_config_key(key.to_s) || self.create(:config_key => key.to_s, :options => default_value)
    DataCache.put_container("Config",key,val.options)
    val
  end
	
  def after_save #:nodoc:
    DataCache.expire_container("Config")
  end
  	
	
  # Get a configuration HashModel by class either using values or pull it from the configurations table
  def self.get_config_model(mdl,values = nil)
    key=  mdl.to_s.underscore

    if values
      mdl.new((get(key)||{ }).symbolize_keys.merge((values || {}).symbolize_keys)) 
    else
      mdl.new(get(key)||{})
    end

  end
  
  # Put a configuration HashModel into the configurations table 
  #
  # Automatically activate any modules in the initialized state if this is a AdminController
  # configuration module
  def self.set_config_model(mdl)

    if mdl.class.to_s =~ /^(.*)\:\:AdminController\:\:(.*)$/
      comp = "#{$1}::AdminController".constantize.get_component_info[0]
      SiteModule.complete_module_initialization(comp)
    end
    key = mdl.class.to_s.underscore
    cfg = retrieve(key)
    cfg.options = mdl.to_h
    cfg.save
  end
  
  # Return the list of activated languages in this website
  def self.languages() 
    lang = self.get(:languages, { :list => [ CMS_DEFAULT_LANGUAGE || 'en' ] } )
    unless lang[:list]
      lang[:list ] = [CMS_DEFAULT_LANGUAGE || 'en' ] 
    end
    lang[:list]
  end


  # Get the domain configuration information (Domain table attribute hash)
  # we don't have a database yet, so we need to look in the webiva
  # db domains table or try to pull from the cache. Can't use the
  # normal DataCache for the same reason (no database to index by), so
  # we need to use a special DataCache.get/set_domain_info function to
  # index just by the name of the domain. Cache is set to an array so
  # that we know the difference between an invalid domain and a
  # domain that's missing form the cache
  def self.fetch_domain_configuration(domain_name)
    cfg = DataCache.get_domain_info(domain_name)
    return cfg[0] if cfg

    dmn = Domain.find_by_name(domain_name)
    # Handle domain level redirects
    if !dmn
      # Set the cache so we don't have to hit the main webiva db for a
      # bunch of duplicate invalid domain requests
      DataCache.set_domain_info(domain_name,[nil])
      return nil
    elsif dmn.domain_type == 'redirect'
      # same as above - set the cache value so we don't have to look
      # each redirect request up
      DataCache.set_domain_info(domain_name,[dmn.redirect])
      return dmn.redirect
    end
    # Otherwise cache the database to avoid a req on the domain
    # table
    cfg = dmn.get_info

    # return nothing if the domain is inactive   
    if cfg[:domain_database][:inactive]
      DataCache.set_domain_info(domain_name,[nil])
      nil
    else
      DataCache.set_domain_info(domain_name,[cfg])
      cfg
    end
  end

  def self.system_module_configuration(mod)
    config = DomainModel.active_domain[:domain_database][:config]
    if config && config['modules'] && config['modules'][mod]
      config['modules'][mod]
    else
      nil
    end
  end

  # Return the google analytics code 
  # TODO: move safely into configuration
  def self.google_analytics
    self.get(:google_analytics, {:enabled => false, :code => '' })
  end
  
  # Return the domain options DomainOptions hash model 
  def self.options(opts=nil)
    if opts
      DomainOptions.new(opts)
    else
      cached_opts = DataCache.local_cache('configuration_domain_options')
      return cached_opts if cached_opts 
      DataCache.put_local_cache('configuration_domain_options',DomainOptions.new(self.get(:options, { } )))
    end
  end

  def self.date_format; self.options.default_date_format.present? ? self.options.default_date_format : DEFAULT_DATE_FORMAT.t; end
  def self.time_format; self.options.default_time_format.present? ? self.options.default_time_format : DEFAULT_TIME_FORMAT.t; end
  def self.datetime_format; self.options.default_datetime_format.present? ? self.options.default_datetime_format :  DEFAULT_DATETIME_FORMAT.t; end
  
  # Return the list of available image sizes
  def self.images_sizes
    self.get(:image_sizes, { :sizes => [] } )
  end
  
  def self.logging #:nodoc:
    true
  end

  # Return the current time zone
  def self.time_zone
    self.options.site_timezone || CMS_DEFAULT_TIME_ZONE
  end
  
  # return a DomainFile for the gender-appropriate missing image
  def self.missing_image(gender=nil)
    gender ||= 'unknown'

    img = DataCache.local_cache("missing_image_#{gender}")
    return img if img

    if gender.to_s == 'm'
      img = DomainFile.find_by_id(self.options.missing_male_image_id) if self.options.missing_male_image_id
    elsif gender.to_s == 'f'
      img = DomainFile.find_by_id(self.options.missing_female_image_id) if self.options.missing_female_image_id
    end
    img ||= DomainFile.find_by_id(self.options.missing_image_id) if self.options.missing_image_id
    
    
    DataCache.put_local_cache("missing_image_#{gender}",img)
    img
  end
  
  # Domain options configured mailing contact email
  def self.mailing_contact
     self.options.mailing_contact_email
  end
  
  # Domain options configured mailing contact name
  def self.mailing_from
    self.options.mailing_default_from_name
  end
 
  # Return domain options configured mailing contact email or return a default
  def self.reply_to_email
     self.options.mailing_contact_email || ("noreply@" +  DomainModel.active_domain_name)
  end
  
  # Return domain options configured mailing contact email or return a default
  def self.from_email
    self.options.mailing_contact_email || ("noreply@" +  DomainModel.active_domain_name)
  end
  
  # Return the current active domain name
  def self.domain
    DomainModel.active_domain_name
  end
  
  # Return the currently active domain id
  def self.domain_id
    DomainModel.active_domain_id
  end
  
  # Wrap a relative link with the currently active domain
  def self.domain_link(url)
    "http://#{self.full_domain}#{url}"
  end
  
  # alias for Configuration#domain_link
  def self.link(url)
    "http://#{self.full_domain}#{url}"
  end
  
  # Return the full domain with the prefixed www if that option is set in the 
  # domain options
  def self.full_domain
    (DomainModel.active_domain[:www_prefix] ? 'www.' : '') + DomainModel.active_domain_name
  end
  
  # Fetch the entry from the Domain table about the current domain
  def self.domain_info
    Domain.find_by_id(self.domain_id)
  end
  
  # Return file type information in the form of a  DomainFileType object
  def self.file_types(val=nil)
    DomainFileType.new(val || self.get(:file_types))
  end
  
  # Information about support file processors, pulled from the Configuration table
  #
  # Attributes:
  #     :processors => list of file processors
  #     :default => default file processor
  class DomainFileType < HashModel
    default_options :processors => ['local'], :default => 'local', :options => {}, :options_arr => {}
    
    def validate # :nodoc:
      self.processors = (self.processors||[]).find_all { |elm| !elm.blank? }
      if self.processors.length <= 0
        errors.add(:processors,'must have a least one selected')
      end
      self.options = self.options.to_hash
      self.options.each do |opt,val|
        options_arr[opt.to_s] = val.split("\n").find_all { |elm| !elm.blank? }
      end
    end
  end

  # Domain level options set in Website Configuration, these can be accessed from
  # Configuration#self.options
  class DomainOptions < HashModel
    include HandlerActions

    attributes :domain_title_name => nil, :mailing_contact_email =>nil,
    :mailing_default_from_name => nil, :company_address => nil, 
    :default_image_location => nil, :gallery_folder => nil, 
    :page_title_prefix => nil, :user_image_folder => nil, 
    :missing_image_id => nil, :missing_male_image_id => nil, 
    :missing_female_image_id => nil, :theme => 'standard', :member_tabs => [],
    :general_activation_template_id => nil,
    :general_activation_url => nil,
    :search_handler => nil,
    :search_stats_handler => nil,
    :site_timezone => nil,
    :captcha_handler => nil,
    :skip_default_feature_css => false,
    :default_date_format => nil,
    :default_datetime_format => nil,
    :default_time_format => nil

    integer_options :default_image_location, :gallery_folder,:user_image_folder, :missing_image_id, :missing_male_image_id, :missing_female_image_id

    boolean_options :skip_default_feature_css

    def validate #:nodoc:
      if !search_handler.blank?
        self.errors.add(:search_handler,'is not valid') unless get_handler_values(:webiva,:search).include?(search_handler)
      end
      if !search_stats_handler.blank?
         self.errors.add(:search_stats_handler,'is not valid') unless get_handler_values(:webiva,:search_stats).include?(search_stats_handler)
      end
      if !captcha_handler.blank?
        self.errors.add(:captcha_handler,'is not valid') unless get_handler_values(:webiva,:captcha).include?(captcha_handler)
      end
    end

    def one_line_address(separator = " | ")
      self.company_address.to_s.split("\n").map(&:strip).join(separator)
    end
  end

  # Log a configuration error into the system
  # TODO / Not implemented (but you should still call this as it will be soon)
  def self.log_config_error(error,data={})
    # Dummy function for now
  end

end
