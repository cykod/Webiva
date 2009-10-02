# Copyright (C) 2009 Pascal Rettig.

# Defines User-configurable domain specific configuration options
class Configuration < DomainModel

  serialize :options
	
  def self.get(key = 'domain',default_value = {})
    val = DataCache.get_cached_container("Config",key)
    return val if val 

    val = self.find_by_config_key(key.to_s) || self.create(:config_key => key.to_s, :options => default_value)
    DataCache.put_container("Config",key,val.options)
    val.options
  end
  
  def self.retrieve(key,default_value = {})
    val = self.find_by_config_key(key.to_s) || self.create(:config_key => key.to_s, :options => default_value)
    DataCache.put_container("Config",key,val.options)
    val
  end
	
  def after_save
    DataCache.expire_container("Config")
  end
  	
	
  def self.get_config_model(mdl,values = nil)
    key=  mdl.to_s.underscore
    mdl.new(values || get(key) || {})
  end
  
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
    cfg = dmn.attributes
    cfg.symbolize_keys!
    DataCache.set_domain_info(domain_name,[cfg])
    cfg
  end
  
  def self.google_analytics
    self.get(:google_analytics, {:enabled => false, :code => '' })
  end
  
  def self.options
    self.get(:options, { } )
  end
  
  def self.images_sizes
    self.get(:image_sizes, { :sizes => [] } )
  end
  
  def self.logging
    true
  end
  
  def self.missing_image(gender)
    DomainFile.find_by_id(self.options[:missing_image_id])
  end
  
  def self.mailing_contact
     self.options[:mailing_contact_email]
  end
  
  def self.mailing_from
    self.options[:mailing_default_from_name]
  end
  
  def self.reply_to_email
     self.options[:mailing_contact_email] || ("noreply@" +  DomainModel.active_domain_name)
  end
  
  def self.from_email
    self.options[:mailing_contact_email] || ("noreply@" +  DomainModel.active_domain_name)
  end
  
  def self.domain
    DomainModel.active_domain_name
  end
  
  def self.domain_id
    DomainModel.active_domain_id
  end
  
  def self.domain_link(url)
    "http://#{self.full_domain}#{url}"
  end
  
  def self.link(url)
    "http://#{self.domain}#{url}"
  end
  
  def self.full_domain
    if DomainModel.active_domain_name.split(".").length == 3
      DomainModel.active_domain_name
    else
      'www.' + DomainModel.active_domain_name
    end
  end
  
  def self.domain_info
    Domain.find_by_id(self.domain_id)
  end
  
  def self.file_types(val=nil)
    DomainFileType.new(val || self.get(:file_types))
  end
  
  class DomainFileType < HashModel
    default_options :processors => ['local'], :default => 'local', :options => {}, :options_arr => {}
    
    def validate
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

end
