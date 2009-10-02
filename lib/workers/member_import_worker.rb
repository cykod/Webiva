# Copyright (C) 2009 Pascal Rettig.

require 'fileutils'
require 'digest/sha1'
require 'csv'

class MemberImportWorker <  BackgrounDRb::Rails
  
  # Args: file_path
  # 
  def do_work(args)
  
    
  
    dmn = Domain.find(args[:domain_id])
    DomainModel.activate_domain(dmn.attributes,'migrator',false)
    
    results[:completed] = false
    
    count = -1
    CSV.open(args[:filename],"r",args[:deliminator]).each do |row|
      count += 1 if !row.join.blank?
    end
    count = 1 if count < 1
    results[:entries] = count
    
    
    results[:initialized] = true
    results[:imported] = 0
    EndUser.import_csv(args[:filename],args[:data],:import => true, :options => args[:options],:deliminator => args[:deliminator]) do |imported,errors|
      results[:imported] += imported
    
    end
    
    results[:completed] = true
    
  end
end
MemberImportWorker.register
