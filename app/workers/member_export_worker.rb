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
    DomainModel.activate_domain(dmn.get_info,'migrator',false)
    
    results[:completed] = false
    
    tmp_path = "#{RAILS_ROOT}/tmp/export/"
    FileUtils.mkpath(tmp_path)
    
    filename  = tmp_path + dmn.id.to_s + "_member_export.csv"
    
    results[:filename] = filename

    @segment = UserSegment.find_by_id args[:user_segment_id]
    
    @fields = []
    if @segment && @segment.fields
      @fields = @segment.fields
    else MembersController.module_options && MembersController.module_options.fields
      @fields = MembersController.module_options.fields
    end

    @default_exported_fields = ['email', 'first_name', 'last_name', 'language', 'dob', 'gender', 'user_level', 'source']

    @fields.reject! do |field|
      info = UserSegment::FieldHandler.display_fields[field.to_sym]
      info.nil? || (info[:handler] == EndUserSegmentField && @default_exported_fields.include?(info[:display_field].to_s))
    end

    idx = 0
    CSV.open(filename,'w') do |writer|
      if @segment
        @segment.find_in_batches do |users|
          @handlers_data = UserSegment.get_handlers_data(users.collect(&:id), @fields)
          users.each do |user|
            user.export_csv(writer, :header => idx == 0,
                            :include => args[:export_options],
                            :handlers_data => @handlers_data,
                            :fields => @fields)
            idx = idx.succ
          end
        end
      else
        EndUser.find_in_batches(:conditions => {:client_user_id => nil}) do |users|
          @handlers_data = UserSegment.get_handlers_data(users.collect(&:id), @fields)
          users.each do |user|
            user.export_csv(writer, :header => idx == 0,
                            :include => args[:export_options],
                            :handlers_data => @handlers_data,
                            :fields => @fields)
            idx = idx.succ
          end
        end
      end
    end

    domain_file = DomainFile.save_temporary_file filename, :name => sprintf("%s_%d.%s",'Email_Targets'.t,Time.now.strftime("%Y_%m_%d"),'csv')

    results[:domain_file_id] = domain_file.id
    results[:entries] = idx
    results[:type] = 'text/csv'
    results[:completed] = 1

    Workling.return.set(args[:uid],results)
  end
end
