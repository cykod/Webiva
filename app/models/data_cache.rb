# Copyright (C) 2009 Pascal Rettig.

=begin rdoc
The DataCache class is a singleton like class that should be used for
all cached storage inside of Webiva. 

It provides two main functions - the first is as an interface for 
interacting with memcache and the second as a single-request storage for
anything that should be cached for the duration of the request (like a piece 
of configuration data read from the database or memcache) 

Class level memoization or the use of class variables is not allowed in rails as
runs for many requests, so setting a class variable will stick around for a while 
and could possibly leak data accross domains. 

As the local data stored in DataCache is cleared at the beginning of each request,
it can be used to store class level data temporarily.

The local cache can be used to store whatever objects needs to be stored - 
DomainModels/etc. - while the normal cache should be used only for simple types:
hashs, arrays, numbers, strings and dates, as these are marshalled and stored
in memcache. 
=end
class DataCache

  @@local_cache = {}

  def self.process_id #:nodoc:
    DomainModel.process_id
  end

  def self.local_cache_store #:nodoc:
    @@local_cache[process_id] ||= {}
  end

  
  # Resets the local cache store and is a called
  # automatically at the beginning of each request
  def self.reset_local_cache
    # Reset the locally cached custom content models as well
    #classes = (DataCache.local_cache("content_models_list") || {}).values
    #classes.each do |cls|
    # Object.send(:remove_const,cls[1]) if Object.const_defined?(cls[1])
    #end
    ContentModelType.subclasses
    classes = {}
    @@local_cache[process_id] = { }

  end
  
  # Returns a value from the local cache or nil if no key exists
  def self.local_cache(key)
    local_cache_store[key]
  end
  
  # Puts a value into the local cache and returns that value
  def self.put_local_cache(key,value)
    local_cache_store[key] = value
  end

  # Get a container from the remote cache
  def self.get_container(container,version)
    return nil if RAILS_ENV == 'test'
    
    # Get the value array [value set time, value]
    unless container.is_a?(String)
      version = container.id.to_s + ":" + version
      container = container.class.to_s
    end
    container_string = DomainModel.active_domain_db + "::" + container
    version_string = container_string + ":" + version.to_s

    DefaultsHashObject
    rev_val = nil
    val  =nil
    begin
      ret_val = CACHE.get_multi(container_string,version_string)
      val = ret_val[version_string]
    rescue MemCache::MemCacheError => e
      return nil
    end
    return nil unless val 
    # Find out when the page was last expired
    expires = ret_val[container_string]
    # Find out if this page is expired or not    
    if !expires || val[0] > expires
      val[1]
    else
      nil
    end
  end

  
  def self.set_domain_info(domain,values) #:nodoc:
    CACHE.set("Domain:#{domain}",values)
  end

  def self.get_domain_info(domain) #:nodoc:
    CACHE.get("Domain:#{domain}")
  end
  
  # Return a container from the remote cached, store it in
  # the local cache and return it. Subsequent calls will
  # hit only the local cache.
  def self.get_cached_container(container,version)
    local_cache_store[container] ||= {}
    return local_cache_store[container][version] if local_cache_store[container][version]
    
    local_cache_store[container][version] = get_container(container,version)
  end

  def self.put_cached_container(container,version,data)
    @@local_cache[container] ||= {}
    @@local_cache[container][version] = data
    self.put_container(container,version,data)
  end
  
  # Put a specific version of an object into the remote cache
  # with an optional expiration in seconds
  def self.put_container(container,version,data,expiration=0)
    unless container.is_a?(String)
      version = container.id.to_s + ":" + version
      container = container.class.to_s
    end
    CACHE.set("#{DomainModel.active_domain_db}::#{container}:#{version}",[ Time.now.to_f,  data ],expiration )
  end
  
  # Expire all versions of a container
  def self.expire_container(container_class)
    CACHE.set("#{DomainModel.active_domain_db}::" + container_class,Time.now.to_f)
  end
  
  # Put a piece of content into the remote cache. See
  # ModelExtension::ContentCacheExtension::ClassMethods#cached_content
  # as using cached_content will prevent you from need to expire the cache
  # manually (it will be expired automatically when the model is saved)
  #
  # content_type = the content type, like "Blog", "BlogPost" or "Comments"
  # content_target = the affected content like the blog.id or blogpost.id
  # display_location = the specific display instance (like a paragraph / etc )
  def self.put_content(content_type,content_target,display_location,data,expiration = 0) 
    begin
      CACHE.set("#{DomainModel.active_domain_db}::Content::#{content_type}::#{content_target}::#{display_location}",[ Time.now.to_f,  data ],expiration )
    rescue ArgumentError => e
      # chomp
    end
  end

  # Pull a piece of content into the remote cache. The cache can be expired
  # by content_type or content_target. See
  # ModelExtension::ContentCacheExtension::ClassMethods#cached_content
  # as using cached_content will prevent you from need to expire the cache
  # manually (it will be expired automatically when the model is saved)
 def self.get_content(content_type,content_target,display_location)
    return nil if RAILS_ENV == 'test'

    # get the value array [value set time, value]
    unless content_type.is_a?(String)
      version = content_type.id.to_s + ":" + version
      container = content_type.class.to_s
    end

    container_string = DomainModel.active_domain_db + "::Content"
    content_type_string = container_string + "::" + content_type
    content_target_string = content_type_string  + "::" + content_target
    display_location_string= content_target_string + "::" + display_location.to_s
    
    ret_val = nil
    begin 
      ret_val = CACHE.get_multi(container_string,content_type_string,content_target_string,display_location_string)
    rescue ArgumentError => e
      ret_val = { }
    end

    val = ret_val[display_location_string]
    return nil unless val
    # find out when the page was last expired
    expires_content = ret_val[container_string]
    expires_content_type = ret_val[content_type_string]
    expires_content_target = ret_val[content_target_string]

    # find out if this page is expired or not    
    if (!expires_content || val[0] > expires_content)  && 
       (!expires_content_type || val[0] > expires_content_type) &&  
       (!expires_content_target || val[0] > expires_content_target)
      val[1]
    else
      nil
    end
  end

 # Expires a piece of content in the remote cache by content_type
 # or by target. This allows you to store many display instances of 
 # a model in the cache, and then expire all of them at once.
 #
 # See ModelExtension::ContentCacheExtension::ClassMethods#cached_content
 # as using cached_content will handle the expiration automatically
 def self.expire_content(content_type = nil,content_target = nil)
   if content_type
     if content_target
       CACHE.set("#{DomainModel.active_domain_db}::Content::#{content_type}::#{content_target}", Time.now.to_f)
     else
       CACHE.set("#{DomainModel.active_domain_db}::Content::#{content_type}", Time.now.to_f)
     end
   else
     CACHE.set("#{DomainModel.active_domain_db}::Content", Time.now.to_f)
   end
 end

# Gets a piece of content from the cache of remote objects
def self.get_remote(content_type,content_target,display_location)
   return nil if RAILS_ENV == 'test'

    # get the value array [value set time, value]
    unless content_type.is_a?(String)
      version = content_type.id.to_s + ":" + version
      container = content_type.class.to_s
    end

    container_string = DomainModel.active_domain_db + "::Remote"
    content_type_string = container_string + "::" + content_type
    content_target_string = content_type_string  + "::" + content_target
    display_location_string= content_target_string + "::" + display_location.to_s
    
    ret_val = CACHE.get_multi(container_string,content_type_string,content_target_string,display_location_string)

    val = ret_val[display_location_string]
    return nil unless val
    # find out when the page was last expired
    expires_content = ret_val[container_string]
    expires_content_type = ret_val[content_type_string]
    expires_content_target = ret_val[content_target_string]

    # find out if this page is expired or not    
    if (!expires_content || val[0] > expires_content)  && 
       (!expires_content_type || val[0] > expires_content_type) &&  
       (!expires_content_target || val[0] > expires_content_target)
      val[1]
    else
      nil
    end
 end

  # Put a piece of content into the remote cache. See
  # ModelExtension::ContentCacheExtension::ClassMethods#cached_content
  # as using cached_content will prevent you from need to expire the cache
  # manually (it will be expired automatically when the model is saved)
  #
  # content_type = the content type, like "Blog", "BlogPost" or "Comments"
  # content_target = the affected content like the blog.id or blogpost.id
  # display_location = the specific display instance (like a paragraph / etc )
  def self.put_remote(content_type,content_target,display_location,data,expiration = 0) 
    CACHE.set("#{DomainModel.active_domain_db}::Remote::#{content_type}::#{content_target}::#{display_location}",[ Time.now.to_f,  data ],expiration )
  end

 def self.logger
   DomainModel.logger
 end


 # Expires the cache for the entire site
 def self.expire_site()
   DataCache.expire_container('SiteNode')
   DataCache.expire_container('Handlers')
   DataCache.expire_container('SiteNodeModifier')
   DataCache.expire_container('Modules')
   DataCache.expire_container("Config")
   DataCache.expire_content
 end

 # Expires the cache for an entire site - domain database must be specified
 def self.expire_domain(db)
   CACHE.set("#{db}::Content", Time.now.to_f)
   %w(SiteNode Handlers SiteNodeModifier Modules).each do |container_class|
     CACHE.set("#{db}::" + container_class,Time.now.to_f) 
   end
 end

end
