# Copyright (C) 2009 Pascal Rettig.

require 'fileutils'
require 'digest/sha1'
require 'csv'
require 'pp'

class MemberExportWorker <  Workling::Base #:nodoc:all
  
  # Args: file_path
  # 
  def do_work(args)
    results = { }
    # args = { :domain_id, :content_model_id, :export_download, :export_format, :range_start, :range_end }
    
    dmn = Domain.find(args[:domain_id])
    DomainModel.activate_domain(dmn.attributes,'migrator',false)
    
    results[:completed] = false
    
    tmp_path = "#{RAILS_ROOT}/tmp/export/"
    FileUtils.mkpath(tmp_path)
    
    filename  = tmp_path + dmn.id.to_s + "_member_export"
    
    results[:filename] = filename
    
    current_segment = MarketSegment.new(:segment_type => 'members',:options => args[:export_segmentation])
    
    @members = current_segment.target_find
     
    CSV.open(filename,'w') do |writer|
      @members.each_with_index do |user,idx|
        user.export_csv(writer,  :header => idx == 0,
                                 :include => args[:export_options])
      end
    end
    results[:entries] = @members.length
    results[:type] = 'csv'
    results[:completed] = 1

    Workling.return.set(args[:uid],results)
  end
end
