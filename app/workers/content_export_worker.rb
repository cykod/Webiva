# Copyright (C) 2009 Pascal Rettig.

require 'fileutils'
require 'digest/sha1'
require 'csv'

class ContentExportWorker <  Workling::Base #:nodoc:all
  
  # Args: file_path
  # 
  def do_work(args)
  
    # args = { :domain_id, :content_model_id, :export_download, :export_format, :range_start, :range_end }
  
    results = { }
    dmn = Domain.find(args[:domain_id])
    DomainModel.activate_domain(dmn.get_info,'migrator',false)
    
    results[:completed] = false
    
    tmp_path = "#{RAILS_ROOT}/tmp/export/"
    FileUtils.mkpath(tmp_path)
    
    content_model = ContentModel.find(args[:content_model_id])
    
    filename  = tmp_path + dmn.id.to_s + "_" +  content_model.table_name + '_export'
    
    results[:filename] = filename
    
    mdl = content_model.content_model
    
    total_entries = mdl.count
    
    if args[:export_download] == 'range'
      @export_offset = args[:range_start].to_i 
      @export_limit = args[:range_end].to_i - args[:range_start].to_i
      @export_limit = 0 if @export_limit < 0
    end
    
    results[:entries] = @export_limit || total_entries

    Workling.return.set(args[:uid],results)
    
    case args[:export_format]
    when 'sql':
    
      dmn_yaml = "#{RAILS_ROOT}/config/sites/#{dmn.database}.yml"
      dmn_file = YAML.load_file(dmn_yaml)
      config = dmn_file['migrator']
    
      # Do mysqldump
      `mysqldump -u #{config['username']} --password="#{config['password']}" --host=#{config['host']} --default-character-set=utf8 --quote-names --complete-insert #{config['database']} #{content_model.table_name} > #{filename}`
      
      results[:type] = 'sql'
    when 'xml':
      File.open(filename,'w') do |f|
        content_model.export_xml(f,:offset => @export_offset, :limit => @export_limit)
      end
      results[:type] = 'xml'
    when 'csv':
      CSV.open(filename,'w') do |writer|
        content_model.export_csv(writer,:offset => @export_offset, :limit => @export_limit)
      end
      results[:type] = 'csv'
    when 'yaml':
      File.open(filename,'w') do |f|
        content_model.export_yaml(f,:offset => @export_offset, :limit => @export_limit)
      end
      results[:type] = 'yaml'
    end

    domain_file = DomainFile.save_temporary_file filename, :name => sprintf("%s_%d.%s",content_model.name.humanize,Time.now.strftime("%Y_%m_%d"),results[:type])

    results[:type] = 'text/' + results[:type]
    results[:domain_file_id] = domain_file.id
    results[:completed] = 1
    Workling.return.set(args[:uid],results)
  end
end
