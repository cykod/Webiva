# Copyright (C) 2009 Pascal Rettig.

require 'fileutils'

# meta function that calls a certain function on a specific
# row in a DomainModel
class DomainModelWorker <  BackgrounDRb::Rails
  
  # Args: file_path
  # 
  def do_work(args)
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

    result_hash = { :processed => false, :successful => true }
    CACHE.set("domain_worker:" + self.jobkey.to_s, result_hash)
    
    if (args[:entry_id].blank?)
      cls.send(args[:method],args[:params] || {})
    else
      entry = cls.find_by_id(args[:entry_id])
      if entry
          entry.send(args[:method],args[:params] || {})
      else
        result_hash[:successful] = false
      end
    end
    
    result_hash[:processed] = true
    CACHE.set("domain_worker:" + self.jobkey.to_s, result_hash)
    self.delete
  end
  
end
DomainModelWorker.register
