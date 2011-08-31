# Copyright (C) 2009 Pascal Rettig.

require 'fileutils'
require 'digest/sha1'
require 'csv'

class MemberImportWorker <  Workling::Base #:nodoc:all
  
  # Args: file_path
  # 
  def do_work(args)
  
    results = { }
  
    dmn = Domain.find(args[:domain_id])
    DomainModel.activate_domain(dmn.get_info,'migrator',false)
    
    results[:completed] = false
    
    file = DomainFile.find_by_id args[:csv_file]
    filename = file.filename

    reader, header = open_csv(filename,args[:deliminator])
    count = 0  
    line = 0
    errors = []
    while !reader.eof?
      begin 
        while !reader.eof?
          line += 1 
          row = reader.shift
          count += 1 if !row.join.blank?
          Rails.logger.error( "(Counted #{line} lines)") if line % 5000 == 0
        end
      rescue Exception => e
        Rails.logger.error( "(Parse Error line #{line} during count)")
        errors << "(Parse Error line #{line} during count)"
      end
    end
    Rails.logger.error( "(Counted #{line} lines)")

    count = 1 if count < 1

    results[:entries] = count
    
    results[:errors] = errors
    results[:initialized] = true
    results[:imported] = 0
    Workling.return.set(args[:uid],results)

    EndUser.import_csv(filename,args[:data],:import => true, :options => args[:options],:deliminator => args[:deliminator]) do |imported, errors|
      results[:imported] += imported
      results[:errors] << "row #{errors[0][0]+2}, error importing \"#{errors[0][1]}\"" unless errors.empty?
      Workling.return.set(args[:uid],results) if (results[:imported] % 10) == 0
    end
    
    results[:completed] = true
    Workling.return.set(args[:uid],results)
  end

  def open_csv(filename,deliminator = ',')
    reader = nil
    header = []
    begin
      reader = FasterCSV.open(filename,"r",:col_sep => deliminator)
      file_fields = reader.shift
    rescue FasterCSV::MalformedCSVError=> e
      reader = FasterCSV.open(filename,"r",:col_sep => deliminator, :row_sep => ?\r)
      file_fields = reader.shift
    end
    return [ reader,header ]
  end

end
