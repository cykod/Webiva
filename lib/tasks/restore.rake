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

    www = ENV['WWW'] ? true : false
    
    ActiveRecord::Base.logger = Logger.new(STDERR)
    ActiveRecord::Base.establish_connection(db_cfg)
    
    
    if ENV['DOMAIN']
      # importing a domain
      domain_name = ENV['DOMAIN']
      client_id = ENV['CLIENT_ID']
      # Create the domain object
      dmn = Domain.create(:name => domain_name, :client_id => client_id, :status => 'initialized',:active => false,:www_prefix => www) 
      dmn.database = 'webiva_' + sprintf("%03d",dmn.id) +  '_' + dmn.name.gsub(/[^a-zA-Z0-9]+/,"_")[0..20] 
      dmn.file_store = dmn.id
      raise 'Existing Domain' if(!dmn.save)
      
      # Create the site config file
      local_db_config = YAML.load_file(directory + "/domain.yml")
      
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

      # Make the database active again
      dmn.update_attributes(:active => false,:status => "initialized")
      
      # Drop the database
      ActiveRecord::Base.connection.execute("DROP DATABASE " + dmn.database)
      
      # Create it again
      ActiveRecord::Base.connection.execute("CREATE DATABASE " + dmn.database)
      
      # import the data
      config_file = "#{RAILS_ROOT}/config/sites/#{dmn.database}.yml"
      local_db_config = YAML.load_file(config_file)
      
    end
    
    cms_import_db(local_db_config['migrator'],directory + "/domain.sql")

    # Activate the domain
    DomainModel.activate_domain(dmn.attributes)
  
    # Delete any rendered parts
    DomainModel.connection.execute("DELETE FROM site_template_rendered_parts WHERE 1")

    # Resave update any file store
    DomainFileInstance.rebuild_all

    
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

    # Clear out the cache for the domain
    DataCache.expire_domain(dmn.database)
      
    # Make the database active again
    dmn.update_attributes(:active => true)
  end
end
