# Copyright (C) 2009 Pascal Rettig.

require 'fileutils'

# meta function that calls a certain function on a specific
# row in a DomainModel
class DomainModelWorker <  Workling::Base #:nodoc:all
  
  # Args: file_path
  # 
  def do_work(args)
    results= { }
    jobkey = args[:uid]
    domain = Domain.find_by_id(args[:domain_id])
    return false unless domain
    
    logger.warn("Running: #{args[:class_name]} #{args[:entry_id]} #{args[:method]}")
    # Don't Save connection
    DomainModel.activate_domain(domain.attributes,'production',false)
    if(args[:language]) 
      language = args[:language]
      Locale.set(language)
    end
    
    class_name = args[:class_name]
    cls = class_name.constantize

    results = { :processed => false, :successful => true }
    Workling.return.set(args[:uid], results)

    if (args[:entry_id].blank?)
      ret_val = cls.send(args[:method],args[:params] || {})
      results.merge!(ret_val) if ret_val.is_a?(Hash)
    else
      entry = cls.find_by_id(args[:entry_id])
      if entry
        ret_val = entry.send(args[:method],args[:params] || {})
        results.merge!(ret_val) if ret_val.is_a?(Hash)
      else
        results[:successful] = false
      end
    end
    
    results[:processed] = true
    Workling.return.set(args[:uid], results)
    
  end
  
end
