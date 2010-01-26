require 'fileutils'
require 'net/ftp'

def cms_backup_dump_db(config,output_file)
  `mysqldump -u #{config['username']} --password="#{config['password']}" --host=#{config['host']} --default-character-set=utf8 --quote-names --complete-insert #{config['database']} > #{output_file}`
end

def cms_backup_file_store(file_store_id,output_dir)
  private_dir = "#{RAILS_ROOT}/public/system/private/#{file_store_id}"
  `cd #{private_dir}; tar -czvf #{output_dir}/private.tar.gz .` if File.exists?(private_dir) && File.directory?(private_dir)
  
  storage_dir = "#{RAILS_ROOT}/public/system/storage/#{file_store_id}"
  `cd #{storage_dir}; tar -czvf #{output_dir}/storage.tar.gz .` if File.exists?(storage_dir) && File.directory?(storage_dir)
end
  
namespace "cms" do 
	desc "Backup the System"
	task :backup => [:environment] do |t|
	
    require 'active_record/schema_dumper'
    require 'logger'
    
    main_db = YAML.load_file("#{RAILS_ROOT}/config/cms_migrator.yml")
    db_cfg = main_db[ENV['RAILS_ENV']]
    
    domain_id = ENV['DOMAIN_ID']
    webiva_db = false

    if domain_id 
      domains = [ Domain.find_by_id(domain_id) ]
    else
      domains = Domain.find(:all,:group => '`database`',:conditions => 'domain_type = "domain"')
      webiva_db = true
    end

    # create a backup directory
    if domain_id
      backup_dir = Time.now.strftime('%Y-%b%d-%H%M%S-') + domains[0].database
    else
      backup_dir =  Time.now.strftime('%Y%m%d%H%M%S')
    end
    
    dir = "#{RAILS_ROOT}/backup/#{backup_dir}"
    FileUtils.mkpath(dir)
    
    ActiveRecord::Base.logger = Logger.new(STDERR)
    ActiveRecord::Base.establish_connection(db_cfg)
    
    
 
    
    # If we need to store the webiva db
    if webiva_db
      webiva_dir = File.join(dir,'system')
      FileUtils.mkpath(webiva_dir)
      # backup database
      cms_backup_dump_db(db_cfg,File.join(webiva_dir,'webiva.sql'))
      # backup config files
      FileUtils.cp_r Dir.glob("#{RAILS_ROOT}/config/*.yml"), webiva_dir
    end
    
    domains.each do |dmn|
      puts("Backing up: " + dmn.name)
      domain_dir = File.join(dir,'domains',dmn.database)
      FileUtils.mkpath(domain_dir)
      
      dmn_yaml = "#{RAILS_ROOT}/config/sites/#{dmn.database}.yml"
      dmn_file = YAML.load_file(dmn_yaml)
      dmn_cfg = dmn_file['migrator']
      
      # backup database
      cms_backup_dump_db(dmn_cfg,File.join(domain_dir,'domain.sql'))
      # backup config file
      FileUtils.cp(dmn_yaml,File.join(domain_dir,'domain.yml'))
      
      cms_backup_file_store(dmn.file_store,domain_dir)
      puts("...Done")
    end
  
    print("Backing up to File: backup/#{backup_dir}.tar.gz\n");
    
    `cd #{RAILS_ROOT}/backup; tar -zcvf #{backup_dir}.tar.gz #{backup_dir}/`
    FileUtils.rm_rf(dir)
    
    if File.exists?("#{RAILS_ROOT}/config/backup.yml") && !ENV['NO_COPY']
      backup_file = YAML.load_file("#{RAILS_ROOT}/config/backup.yml")
      backup_cfg = backup_file['server']
      
      case backup_cfg['type']
      when 'ftp':
        begin 
	  Net::FTP.open(backup_cfg['host'],backup_cfg['username'],backup_cfg['password']) do |ftp|
	    ftp.chdir(backup_cfg['directory']) if backup_cfg['directory']
	    puts("Transmitting Backup file data...")
	    iter = 0
	    ftp.putbinaryfile("#{RAILS_ROOT}/backup/#{backup_dir}.tar.gz","#{backup_dir}.tar.gz") do |data|
	      
	      iter += 1
	      
	      print("#") if iter % 40 == 0
	      print("\n") if iter % 2000 == 0
	      STDOUT.flush
	    end
	    puts("\nDone Transmitting Files")
	    files = ftp.nlst
	    puts("Found #{files.length} existing backup files")
	    backup_limit = backup_cfg['limit'] || 10
	    if files.length >  backup_limit
	      delete_cnt =  files.length - backup_limit
	      # Get the sorted files, with the oldest first
	      files = files.sort
	      
	      puts("Deleting #{delete_cnt} extra backup files")
	      files[0..(delete_cnt-1)].each do |fl|
	        puts("Deleting: " + fl)
		ftp.delete(fl)
	      end
	      
	    end
	  end
	  
	  FileUtils.rm("#{RAILS_ROOT}/backup/#{backup_dir}.tar.gz")
	rescue Exception => e
	 raise "Error FTPing files:" + e.to_s
	end
      else
        raise 'Invalid Backup server type'
      end
      
    
    else
      print("BACKUP DISABLED")
    end
  end
end
