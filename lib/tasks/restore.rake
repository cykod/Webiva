require 'fileutils'
require 'net/ftp'

def cms_import_db(config,input_file)
  `mysql -u #{config['username']} --password="#{config['password']}" --host=#{config['host']} #{config['database']} < #{input_file}`
end

namespace "cms" do 
	desc "Restore a Domain"
	task :restore => [:environment] do |t|
	
    require 'active_record/schema_dumper'
    require 'logger'
    
    raise 'Params DIR=directory [DOMAIN=domain_to_restore CLIENT_ID=client_id] OR [DOMAIN_ID=domain_id_to_replace]' unless ENV['DIR'] && ((ENV['DOMAIN'] && ENV['CLIENT_ID']) || ENV['DOMAIN_ID'])
    
    main_db = YAML.load_file("#{RAILS_ROOT}/config/cms_migrator.yml")
    db_cfg = main_db[ENV['RAILS_ENV']]
    
    
    directory = ENV['DIR']
    
    ActiveRecord::Base.logger = Logger.new(STDERR)
    ActiveRecord::Base.establish_connection(db_cfg)
    
    
    if ENV['DOMAIN']
      # importing a domain
      domain_name = ENV['DOMAIN']
      client_id = ENV['CLIENT_ID']
      # Create the domain object
      dmn = Domain.create(:name => domain_name, :client_id => client_id, :status => 'initialized') 
      dmn.database = 'webiva_' + sprintf("%03d",dmn.id) +  '_' + dmn.name.gsub(/[^a-zA-Z0-9]+/,"_")[0..20] 
      dmn.file_store = dmn.id
      raise 'Existing Domain' if(!dmn.save)
      
      # Create the site config file
      local_db_config = YAML.load_file(directory + "/domain.yml")
      
      # get the old file store for updating the db
      old_file_store = local_db_config['production']['file_store']
      if !old_file_store
        if local_db_config['migrator']['username'] =~ /cms_([0-9]+)_m/
          old_file_store = $1
        end
      end
      local_db_config['migrator']['database'] = dmn.database
      local_db_config['migrator']['file_store'] = dmn.file_store
      local_db_config['migrator']['username'] = "cms_#{dmn.id}_m"
      local_db_config['production']['database'] = dmn.database
      local_db_config['production']['file_store'] = dmn.file_store
      local_db_config['production']['username'] = "cms_#{dmn.id}_user"
      
      config_file = "#{RAILS_ROOT}/config/sites/#{dmn.database}.yml"
      File.open(config_file,"w") do |fd|
        YAML.dump(local_db_config,fd)
      end
      
      # Now Create the database
      ActiveRecord::Base.connection.execute("CREATE DATABASE " + dmn.database)
    
      # Grant rights to user
      user_name = local_db_config['production']['username']
      user_password= local_db_config['production']['password']
      ActiveRecord::Base.connection.execute("GRANT SELECT,INSERT,UPDATE,DELETE ON #{dmn.database}.* TO '#{user_name}'@localhost IDENTIFIED BY '#{user_password}'")
    
      # Grant rights to migrator
      migrator_name = local_db_config['migrator']['username']
      migrator_password = local_db_config['migrator']['password']
      ActiveRecord::Base.connection.execute("GRANT ALL ON #{dmn.database}.* TO '#{migrator_name}'@localhost IDENTIFIED BY '#{migrator_password}'")
    
    
      
    
    elsif ENV['DOMAIN_ID']
    
      dmn = Domain.find(ENV['DOMAIN_ID'])
      
      # Drop the database
      ActiveRecord::Base.connection.execute("DROP DATABASE " + dmn.database)
      
      # Create it again
      ActiveRecord::Base.connection.execute("CREATE DATABASE " + dmn.database)
      
      # import the data
      config_file = "#{RAILS_ROOT}/config/sites/#{dmn.database}.yml"
      local_db_config = YAML.load_file(config_file)
      
      # get the old file store
      old_config_file = YAML.load_file(directory + "/domain.yml")
      old_file_store = old_config_file['production']['file_store']
      if !old_file_store
        if old_config_file['migrator']['username'] =~ /cms_([0-9]+)_m/
          old_file_store = $1
        end
      end      
      
      # update the data 
    
    
    end
    
    cms_import_db(local_db_config['migrator'],directory + "/domain.sql")
  
    # Connect to the new db
    DomainModel.establish_connection(local_db_config['migrator'])
    
    # Update the paragraphs
    DomainModel.connection.execute("UPDATE page_paragraphs SET display_body=REPLACE(display_body,'/system/storage/#{old_file_store}/','/system/storage/#{dmn.file_store}/') WHERE display_type IN('html','code') AND display_body LIKE '%/system/storage/#{old_file_store}/%'")
    
    # Delete any rendered parts
    DomainModel.connection.execute("DELETE FROM site_template_rendered_parts WHERE 1")
    
    if(File.exists?(directory + "/storage.tar.gz"))
      
      storage_dir = "#{RAILS_ROOT}/public/system/storage/#{dmn.file_store}" 
      FileUtils.rm_rf(storage_dir) if(File.directory?(storage_dir))
        
      FileUtils.mkdir_p(storage_dir) 
      `tar -xzf #{directory + "/storage.tar.gz"} -C #{storage_dir}`
    end
    
    if(File.exists?(directory + "/private.tar.gz"))
    
      private_dir = "#{RAILS_ROOT}/public/system/private/#{dmn.file_store}" 
      FileUtils.rm_rf(private_dir) if(File.directory?(private_dir))
      FileUtils.mkdir_p(private_dir) 
      `tar -xzf #{directory + "/private.tar.gz"} -C #{private_dir}`
    end
      
  end
end
