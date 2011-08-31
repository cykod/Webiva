# Copyright (C) 2009 Pascal Rettig.
# 
# Assorted Monkey patches onto existing Rails and Plugin classes



# ActionController Monkey Patches
module ActionController  #:nodoc:all
  class Response #:nodoc:
    def data
      @response_data ||= {}
      @response_data
    end
  end

  class Request #:nodoc:
    @@bots = ["google", "bot", "yahoo", "spider", "archiver", "curl", "python", "nambu", "twitt", "perl", "sphere", "pear", "java", "wordpress", "radian", "crawl", "yandex", "eventbox", "monitor", "mechanize", "facebook", "slurp", "msnbot", "nutch", "search", "wget"]
    def self.bots
      @@bots
    end

    def bot?
      return @is_bot if ! @is_bot.nil?
      agent = user_agent.to_s.downcase
      @is_bot = self.class.bots.detect { |b| agent.include?(b) } ? true : false
    end
  end

  module Session
    class AbstractStore
      class SessionHash
        # Tell Rails that the session was not changed, prevents the session cookie from being stored
        # in Rails 3 the SessionHash is located in module ActionDispatch::Session::AbstractStore
        # set session.unchanged! just before call render
        def unchanged!
          @env[ENV_SESSION_OPTIONS_KEY][:expire_after] = nil
          @loaded = false
        end
      end
    end
  end
end

ActionView::Base.field_error_proc = Proc.new{ |html_tag, instance| html_tag.match(/type=(\'|\")radio(\'|\")/i) ? "<span class=\"radioWithErrors\">#{html_tag}</span>" : "<span class=\"fieldWithErrors\">#{html_tag}</span

>" }
#module ActionView::Helpers::TextHelper
#  def truncate(text, length = 30, truncate_string = '...')
#    if text.nil? then return end
#    l = length - truncate_string.length
#    text.length > length ? text[0...l] + truncate_string : text
#  end
#end

# Monkey Patch Globalize to do no translation if we are on the base language
module Globalize #:nodoc:all
  class Locale
    @@translation_requests = []
    @@cache_translation_requests = false

    def self.translate(key, default = nil, arg = nil, namespace = nil) # :nodoc:
      return key if base? && !default && !arg
      key = key.to_s.gsub('_', ' ') if key.kind_of? Symbol

      if @@cache_translation_requests
        @@translation_requests << key
      end

      val =translator.fetch(key, self.language, default, arg, namespace)
      
    end
    
    def self.save_requests
      clear_requests
      @@cache_translation_requests = true
    end

    def self.retrieve_requests
      requests = @@translation_requests
      @@cache_translation_requests = false 
      clear_requests
      requests
    end
    
    def self.clear_requests
      @@translation_requests = []
    end

  end
  
end

class Fixnum  #:nodoc:all
  def clamp(min,max=nil)
    if self < min
      min
    elsif max && self > max
      max
    else
      self
    end
  end
end

class Module  #:nodoc:all
   alias :rails_official_const_missing :const_missing

   def const_missing(class_id)
     class_id_str = class_id.to_s
     if class_id_str != 'CmsController' && class_id_str.index("Cms") == 0
      ContentModel.content_model(class_id_str.underscore.pluralize)
     else
      rails_official_const_missing(class_id)
    end
   end

end

class Time  #:nodoc:all
        def to_date
                Date.new(year, month, day)
                rescue NameError
                nil
        end

        def to_datetime
                DateTime.new(year, month, day, hour, min, sec)
                rescue NameError
                nil
        end

        
        def self.parse_date(str)
          return nil unless str
          val = Date.strptime(str,Configuration.date_format)
          return val.to_time
        end
        
        def self.parse_datetime(str)
          return nil unless str
          val = nil
          begin 
            val = DateTime.strptime(str,Configuration.datetime_format)
          rescue 
            begin
              val = DateTime.strptime(str,"%m/%d/%Y %H:%M".t)
            rescue
              val = DateTime.strptime(str,"%Y-%m-%d %H:%M:%S")
            end
          end
          return val.to_time
        end
end

class DateTime  #:nodoc:all
        def to_time
                Time.local(year,month,day,hour,min,sec)
        end
end

class Date  #:nodoc:all
        def to_time
                Time.local(year,month,day)
        end

end 


module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module Quoting
      # Convert dates and times to UTC so that the following two will be equivalent:
      # Event.all(:conditions => ["start_time > ?", Time.zone.now])
      # Event.all(:conditions => ["start_time > ?", Time.now])
      def quoted_date(value)
        value.respond_to?(:utc) ? value.utc.to_s(:db) : value.to_s(:db)
      end
    end
  end
end


#class CGI::Session::MemCacheStore
# def check_id(id) #:nodoc:# 
#     /[^0-9a-zA-Z\-._]+/ =~ id.to_s ? false : true 
# end
#end

