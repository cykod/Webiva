# Copyright (C) 2009 Pascal Rettig.


# Moves content caching into the model to automate cache expiration
module ModelExtension::ContentCacheExtension


 
  module ClassMethods

    # update: 
    def cached_content(options = {})

      # After create - only the list should be expired
      after_create :content_cache_expire_list

      # After
      after_save :content_cache_expire
      after_destroy :content_cache_expire

      options.symbolize_keys!

      # other unique identifiers that we might be updating
      if options[:identifier] && !options[:identifier].is_a?(Array)
        options[:identifier] = [ options[:identifier] ] 
      end

      # relationships that need to be expired when we expire
      if options[:update] && !options[:update].is_a?(Array)
        options[:update] = [ options[:update] ]
      end      

      self.send(:include, ModelExtension::ContentCacheExtension::InstanceMethods)
      define_method(:content_cache_expire_options) do
        options
      end
    end

    def expires_site
      after_save :expire_site_full
      after_destroy :expire_site_full

      self.send(:include, ModelExtension::ContentCacheExtension::ExpireSiteInstanceMethods)
    end

  end


  def self.append_features(mod)
    super
    mod.extend ModelExtension::ContentCacheExtension::ClassMethods
  end


  module ExpireSiteInstanceMethods
    def expire_site_full
      DataCache.expire_container('SiteNode')
      DataCache.expire_container('Handlers')
      DataCache.expire_container('SiteNodeModifier')
      DataCache.expire_content
    end
 
  end
  
  module InstanceMethods 
    def content_cache_expire_options; {}; end

    # Expire any lists data cache elements
    def content_cache_expire_list
      DataCache.expire_content(self.class.to_s,'LIST')
    end

    # Expire this content element 
    def content_cache_expire
      opts = content_cache_expire_options

      content_cache_expire_list
      
      DataCache.expire_content(self.class.to_s,"ID#{self.id}")
      logger.warn("Content Cache Expire: #{self.class.to_s} ID#{self.id}") unless RAILS_ENV == 'production'
      if opts[:identifier]
        opts[:identifier].each do |ident|
          # We are only using the first 46 characters of the identifier
          # b/c of memcached size issues
          ident = "ATR#{self.resolve_argument(ident).to_s[0..45]}"
          logger.warn("Content Cache Expire: #{self.class.to_s} #{ident}") unless RAILS_ENV == 'production'
          DataCache.expire_content(self.class.to_s,ident)
         
          
        end
      end

      # Go through and update any relationships
      if opts[:update]
        opts[:update].each do |relationship|
          if elm = self.send(relationship)
            elm.to_a.each do |chld|
              chld.content_cache_expire
              # Call content cache expire on
              # any of those relationships
            end
          end
        end
      end
    end

  

  
    def cache_fetch(display_string,identifier=nil)
      ident = identifier ? "ATR#{self.resolve_argument(identifier).to_s[0..45]}" : "ID#{self.id}"
      logger.warn("Content Cache Fetch: #{self.class.to_s} #{ident} #{display_string}") unless RAILS_ENV == 'production'
      
      DataCache.get_content(self.class.to_s,
                            ident,
                            display_string)
      
    end

    def cache_put(display_string,content,identifier=nil)
      ident = identifier ? "ATR#{self.resolve_argument(identifier).to_s[0..45]}" : "ID#{self.id}"

      logger.warn("Content Cache Put: #{self.class.to_s} #{ident} #{display_string} (#{content.to_s.length})") unless RAILS_ENV == 'production'
      
      DataCache.put_content(self.class.to_s,
                            ident,
                            display_string,
                            content)
    end


    def cache_put_list(display_string,content)
      self.class.cache_put_list(display_string,content)
    end

    def self.append_features(mod)
      super
      mod.extend ModelExtension::ContentCacheExtension::InstanceMethods::CacheClassMethods
    end

    module CacheClassMethods
      def cache_put_list(display_string,content)
        DataCache.put_content(self.to_s,
                              "LIST",
                              display_string,
                              content)
      end
      
      def cache_fetch_list(display_string)
        DataCache.get_content(self.to_s,
                              'LIST',
                              display_string)
      end
      
      def cache_fetch(display_string,identifier)
        # See if we're pulling by id or identifier
        if identifier.is_a?(Integer)
          ident = "ID#{identifier}"
        else
          ident = "ATR#{identifier.to_s[0..45]}"
        end
        logger.warn("Content Cache Fetch: #{self.to_s}  #{ident} #{display_string}") unless RAILS_ENV == 'production'
        DataCache.get_content(self.to_s,ident,display_string)
      end

      def cache_put(display_string,content,identifier)
        # See if we're putting by id or identifier
        if identifier.is_a?(Integer)
          ident = "ID#{identifier}"
        else
          ident = "ATR#{identifier.to_s[0.45]}"
        end
        
        logger.warn("Content Cache Put: #{self.to_s} #{ident} #{display_string} (#{content.to_s.length})") unless RAILS_ENV == 'production'
        
        DataCache.put_content(self.to_s,ident,display_string,content)
      end
    end
  end
  
end  
