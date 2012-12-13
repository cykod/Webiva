require 'fileutils'
require 'net/ftp'

  
namespace "cms" do 
	desc "Copyover a domain from another server"
	task :copyover => [:environment] do |t|

    server = ENV['SERVER']
    domain = ENV['SOURCE']

    restore = ENV['RESTORE']
    restore_id = ENV['RESTORE_ID']

    if !server || !domain || !(restore || restore_id)
      raise 'Params SERVER=source_server.com SOURCE=source_domain.com [RESTORE=restore-to-new-domain.com or RESTORE_ID=EXISTING_ID]'
    end

    if restore.to_s.upcase == 'SAME'
      restore = domain
    elsif restore_id.to_s.upcase == 'SAME'
      restore_domain = Domain.where(:name => domain).first

      if !restore_domain
        raise "Couldn't find existing local domain #{domain}"
      end

      restore_id = restore_domain.id
    end

    copy_local = nil 
    if ENV['COPY_LOCAL'] 
      copy_local = 'COPY_LOCAL=1' 
    end 

    puts "###############################################################"
    puts "Running Backup on Remote Server........."
    puts "###############################################################"
    puts `ssh -t webiva@#{server} 'cd current; rake cms:backup DOMAIN=#{domain} FILENAME=backupfile NO_COPY=1 #{copy_local}'`

    puts "###############################################################"
    puts "Copying to Local........."
    puts "###############################################################"
    puts `scp webiva@#{server}:~/current/backup/backupfile.tar.gz #{RAILS_ROOT}/backup/` 
    `ssh -t webiva@#{server} 'cd current; rm backup/backupfile.tar.gz'`

    puts "###############################################################"
    puts "Untarring ........."
    puts "###############################################################"
    `cd #{RAILS_ROOT}/backup; tar -xzf backupfile.tar.gz`
     dir = Dir.glob("#{RAILS_ROOT}/backup/backupfile/domains/*")[0]


    puts "###############################################################"
    puts "Running Restore........."
    puts "###############################################################"
     if restore.present?
       `rake cms:restore DOMAIN=#{restore} CLIENT_ID=1 DIR=#{dir} RAILS_ENV=production `
     elsif restore_id.present?
       `rake cms:restore DOMAIN_ID=#{restore_id} DIR=#{dir} RAILS_ENV=production`
     end

    puts "###############################################################"
    puts "Cleaning Up........."
    puts "###############################################################"
     `rm -r '#{RAILS_ROOT}/backup/backupfile/'`

     `mv #{RAILS_ROOT}/backup/backupfile.tar.gz #{RAILS_ROOT}/backup/restored_#{Time.now.strftime("%Y-%m-%d")}_#{restore || restore_id}.tar.gz`

    puts "###############################################################"
    puts "Done........."
    puts "###############################################################"

  end

	desc "Copyover a domain from another server"
	task :copyonly => [:environment] do |t|

    server = ENV['SERVER']
    domain = ENV['SOURCE']

    if !server || !domain 
      raise 'Params SERVER=source_server.com SOURCE=source_domain.com'
    end

    copy_local = nil 
    if ENV['COPY_LOCAL'] 
      copy_local = 'COPY_LOCAL=1' 
    end 

    puts "###############################################################"
    puts "Running Backup on Remote Server........."
    puts "###############################################################"
    puts `ssh -t webiva@#{server} 'cd current; rake cms:backup DOMAIN=#{domain} FILENAME=backupfile NO_COPY=1 #{copy_local}'`

    puts "###############################################################"
    puts "Copying to Local........."
    puts "###############################################################"
    puts `scp webiva@#{server}:~/current/backup/backupfile.tar.gz #{RAILS_ROOT}/backup/` 
    `ssh -t webiva@#{server} 'cd current; rm backup/backupfile.tar.gz'`

    final_file = "#{RAILS_ROOT}/backup/copied_#{Time.now.strftime("%Y-%m-%d")}_#{domain}.tar.gz"
    `mv #{RAILS_ROOT}/backup/backupfile.tar.gz #{final_file}`

    puts "###############################################################"
    puts "Done........."
    puts "###############################################################"
  
    puts "File is: #{final_file}"

  end



end

