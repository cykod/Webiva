# Copyright (C) 2009 Pascal Rettig.


# Moves content caching into the model to automate cache expiration
module ModelExtension::ContentCacheExtension
 
  module ClassMethods 

    # Call cached_content to enable the cache extensions on a DomainModel
    # this allows this object to be used in ParagraphRenderer#renderer_cache
    # or by using the object class and instance methods to cache data in 
    # an object
    #
    # Usage examples (in class definition):
    #
    #         cached_content
    #              OR
    #         cached_content :identifier => :url, :update => [ :some_container_relation ]
    #
    # === Caching overview
    # Caching works by operating on a class, an identifier and a display string. The class is
    # whatever class cached_content is added to, the identifier is either an individual id
    # or a entire class and the display_string is the individual display instance that we want to
    # cached. Saving any element will expire all display strings in the cache for that individual 
    # entry as well as the entire class. 
    #
    # The real issue left to the programmer is coming up with a unique display string for each 
    # different pice of information you want to cache.  ParagraphRenderer#renderer_cache automatically
    # adds a paragraph_id but you may need to add additional information like a page, etc.
    #
    # === Options
    # 
    # [:identifier] 
    #   This is a attribute that should be used as an additional identifier for cached content
    #   in addition to the id attribute. This allows the use of the class level #cache_fetch 
    #   method to check the cache without needing to do a find for the actual object if it's not needed
    # [:update]
    #   These are the names of relations whose cache should expire when this objects cache expires
    # [:update_list]
    #   These are the names of classes whose list cache should expire when this objects cache expires
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

      # relationships that need to be expired when we expire
      if options[:update_list] && !options[:update_list].is_a?(Array)
        options[:update_list] = [ options[:update_list] ]
      end      

      self.send(:include, ModelExtension::ContentCacheExtension::InstanceMethods)
      define_method(:content_cache_expire_options) do
        options
      end
    end

    # Saving an row of this object will expire the entire site
    def expires_site
      after_save :expire_site_full
      after_destroy :expire_site_full

      self.send(:include, ModelExtension::ContentCacheExtension::ExpireSiteInstanceMethods)
    end

  end


  def self.append_features(mod) #:nodoc:
    super
    mod.extend ModelExtension::ContentCacheExtension::ClassMethods
  end


  module ExpireSiteInstanceMethods
    # Expire the entire site
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
      self.class.content_cache_expire_list
    end

    # Expire this content element manually
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
      
      if opts[:update_list]
        opts[:update_list].each do |lst|
          lst.constantize.content_cache_expire_list
        end
          
      end

      # Go through and update any relationships
      if opts[:update]
        opts[:update].each do |relationship|
          if elm = self.send(relationship)
            elm = [ elm ] unless elm.respond_to?(:each)
            elm.each do |chld|
              chld.content_cache_expire
              # Call content cache expire on
              # any of those relationships
            end
          end
        end
      end
    end

  

    # Fetch data from the cache for this object, identifier is an optional
    # attribute symbol, or proc that will search by the cache by identifier instead of id
    def cache_fetch(display_string,identifier=nil)
      ident = identifier ? "ATR#{self.resolve_argument(identifier).to_s[0..45]}" : "ID#{self.id}"
      logger.warn("Content Cache Fetch: #{self.class.to_s} #{ident} #{display_string}") unless RAILS_ENV == 'production'
      
      DataCache.get_content(self.class.to_s,
                            ident,
                            display_string)
      
    end


    # Put data in the cache associated with this object and an option identifier
    def cache_put(display_string,content,identifier=nil,expiration=0)
      ident = identifier ? "ATR#{self.resolve_argument(identifier).to_s[0..45]}" : "ID#{self.id}"

      logger.warn("Content Cache Put: #{self.class.to_s} #{ident} #{display_string} (#{content.to_s.length})") unless RAILS_ENV == 'production'
      
      DataCache.put_content(self.class.to_s,
                            ident,
                            display_string,
                            content,
                            expiration)
    end

    # Put data into the cache associated with all objects in the content_cache'd class
    def cache_put_list(display_string,content,expiration=0)
      self.class.cache_put_list(display_string,content,expiration=0)
    end

    def self.append_features(mod) #:nodoc:
      super
      mod.extend ModelExtension::ContentCacheExtension::InstanceMethods::CacheClassMethods
    end

    module CacheClassMethods

      def cache_expire_by_id(item_id)
         DataCache.expire_content(self.to_s,"ID#{item_id}")
         content_cache_expire_list
      end

      # Expire any lists data cache elements
      def content_cache_expire_list 
        logger.warn("Content Cache Expire List: #{self.to_s}") unless RAILS_ENV == 'production'
        DataCache.expire_content(self.to_s,'LIST')
      end


      # Put data into the cache associated with the content_cache'd class
      def cache_put_list(display_string,content,expiration=0)
        logger.warn("Content Cache Put List: #{self.to_s} #{display_string}") unless RAILS_ENV == 'production'
        DataCache.put_content(self.to_s,
                              "LIST",
                              display_string,
                              content,
                              expiration)
      end
      
      # Pull data out of the list cache given a display string
      def cache_fetch_list(display_string)
        logger.warn("Content Cache Fetch List: #{self.to_s} #{display_string}") unless RAILS_ENV == 'production'

        DataCache.get_content(self.to_s,
                              'LIST',
                              display_string)
      end
      
      # Pull the cache for an individual object given only the identifier for that 
      # object (so you don't need to hit the DB to pull) - either an id or the 
      # value of the field in the :identifier option to cached_content
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

      # Put to the cache for an individual object given only the identifier for that 
      # object (so you don't need to hit the DB to pull) - either an id or the 
      # value of the field in the :identifier option to cached_content
      def cache_put(display_string,content,identifier,expiration=0)
        # See if we're putting by id or identifier
        if identifier.is_a?(Integer)
          ident = "ID#{identifier}"
        else
          ident = "ATR#{identifier.to_s[0..45]}"
        end
        
        logger.warn("Content Cache Put: #{self.to_s} #{ident} #{display_string} (#{content.to_s.length})") unless RAILS_ENV == 'production'
        
        DataCache.put_content(self.to_s,ident,display_string,content,expiration)
      end
    end
  end
  
end  
