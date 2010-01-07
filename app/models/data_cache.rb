# Copyright (C) 2009 Pascal Rettig.


class DataCache

  @@local_cache = {}

  def self.process_id
    DomainModel.process_id
  end

  def self.local_cache_store
    @@local_cache[process_id] ||= {}
  end

  
  def self.reset_local_cache
    # Reset the locally cached custom content models as well
    classes = (DataCache.local_cache("content_models_list") || {}).values
    classes.each do |cls|
     Object.send(:remove_const,cls[1]) if Object.const_defined?(cls[1])
    end
    classes = {}

    @@local_cache[process_id] = { }

    ContentModelType.subclasses
  end
  
  def self.local_cache(key)
    local_cache_store[key]
  end
  
  def self.put_local_cache(key,value)
    local_cache_store[key] = value
  end

  # Get a specific version of an object
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
    
    ret_val = CACHE.get_multi(container_string,version_string)
    val = ret_val[version_string]
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

  def self.set_domain_info(domain,values)
    CACHE.set("Domain:#{domain}",values)
  end

  def self.get_domain_info(domain)
    CACHE.get("Domain:#{domain}")
  end
  
  def self.get_cached_container(container,version)
    local_cache_store[container] ||= {}
    return local_cache_store[container][version] if local_cache_store[container][version]
    
    local_cache_store[container][version] = get_container(container,version)
  end
  
  # Put a specific version of an object
  def self.put_container(container,version,data)
    unless container.is_a?(String)
      version = container.id.to_s + ":" + version
      container = container.class.to_s
    end
    CACHE.set("#{DomainModel.active_domain_db}::#{container}:#{version}",[ Time.now.to_f,  data ] )
  end
  
  def self.expire_container(container_class)
    CACHE.set("#{DomainModel.active_domain_db}::" + container_class,Time.now.to_f)
  end
  

  # content_type = the content type, like "Blog", "BlogPost" or "Comments"
  # content_target = the affected content like the blog.id or blogpost.id
  # display_location = the specific display instance (like a paragraph / etc )
  
  def self.put_content(content_type,content_target,display_location,data) 
    CACHE.set("#{DomainModel.active_domain_db}::Content::#{content_type}::#{content_target}::#{display_location}",[ Time.now.to_f,  data ] )
  end

 def self.get_content(content_type,content_target,display_location)
    return nil if RAILS_ENV == 'test'

    # Get the value array [value set time, value]
    unless content_type.is_a?(String)
      version = content_type.id.to_s + ":" + version
      container = content_type.class.to_s
    end

    container_string = DomainModel.active_domain_db + "::Content"
    content_type_string = container_string + "::" + content_type
    content_target_string = content_type_string  + "::" + content_target
    display_location_string= content_target_string + "::" + display_location.to_s
    
    ret_val = CACHE.get_multi(container_string,content_type_string,content_target_string,display_location_string)

    val = ret_val[display_location_string]
    return nil unless val
    # Find out when the page was last expired
    expires_content = ret_val[container_string]
    expires_content_type = ret_val[content_type_string]
    expires_content_target = ret_val[content_target_string]

    # Find out if this page is expired or not    
    if (!expires_content || val[0] > expires_content)  && 
       (!expires_content_type || val[0] > expires_content_type) &&  
       (!expires_content_target || val[0] > expires_content_target)
      val[1]
    else
      nil
    end
  end


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

end
