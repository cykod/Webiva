# Copyright (C) 2009 Pascal Rettig.

require 'fileutils'
require 'digest/sha1'
require 'csv'

class ContentImportWorker <  BackgrounDRb::Rails
  
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
    
    
    content_model = ContentModel.find(args[:content_model_id])
    
    results[:initialized] = true
    results[:imported] = 0
    content_model.import_csv(args[:filename],args[:data],:import => true,:deliminator => args[:deliminator]) do |imported,errors|
      results[:imported] += imported
    
    end
    
    results[:completed] = true
    
  end
end

ContentImportWorker.register
