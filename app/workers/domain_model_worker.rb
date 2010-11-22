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
    DomainModel.activate_domain(domain.get_info,'production',false)
    if(args[:language]) 
      language = args[:language]
      Locale.set(language)
    end
    
    class_name = args[:class_name]
    cls = class_name.constantize

    results = { :processed => false, :successful => true }
    Workling.return.set(jobkey, results)

    params = args[:params] || {}
    params[:uid] = jobkey

    if args[:hash_model]
      entry = cls.new args[:attributes]
      ret_val = entry.send(args[:method], params)
      results.merge!(ret_val) if ret_val.is_a?(Hash)
    elsif args[:entry_id].blank?
      ret_val = cls.send(args[:method], params)
      results.merge!(ret_val) if ret_val.is_a?(Hash)
    else
      entry = cls.find_by_id(args[:entry_id])
      if entry
        ret_val = entry.send(args[:method], params)
        results.merge!(ret_val) if ret_val.is_a?(Hash)
      else
        results[:successful] = false
      end
    end
    
    results[:processed] = true
    Workling.return.set(jobkey, results)
    
  end
  
end
