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

      # Create the site config file
      local_db_config = YAML.load_file(directory + "/domain.yml")
      
      local_db_config['migrator']['database'] = dmn.database
      local_db_config['migrator']['file_store'] = dmn.file_store
      local_db_config['migrator']['username'] = "cms_#{dmn.id}_m"
      local_db_config['migrator']['host'] = db_cfg['host']
      local_db_config['production']['database'] = dmn.database
      local_db_config['production']['file_store'] = dmn.file_store
      local_db_config['production']['username'] = "cms_#{dmn.id}_user"
      local_db_config['production']['host'] = db_cfg['host']
      
      dmn.create_domain_database :client_id => dmn.client_id, :name => dmn.database, :options => local_db_config

      raise 'Existing Domain' if(!dmn.save)
      
      # Now Create the database
      ActiveRecord::Base.connection.execute("CREATE DATABASE " + dmn.database)
    
      # Grant rights to user
      user_name = local_db_config['production']['username']
      user_password= local_db_config['production']['password']
      ActiveRecord::Base.connection.execute("GRANT SELECT,INSERT,UPDATE,DELETE ON #{dmn.database}.* TO '#{user_name}'@'%' IDENTIFIED BY '#{user_password}'")
      ActiveRecord::Base.connection.execute("GRANT SELECT,INSERT,UPDATE,DELETE ON #{dmn.database}.* TO '#{user_name}'@localhost IDENTIFIED BY '#{user_password}'")
    
      # Grant rights to migrator
      migrator_name = local_db_config['migrator']['username']
      migrator_password = local_db_config['migrator']['password']
      ActiveRecord::Base.connection.execute("GRANT ALL ON #{dmn.database}.* TO '#{migrator_name}'@'%' IDENTIFIED BY '#{migrator_password}'")
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
      local_db_config = dmn.get_info[:domain_database][:options]
      
    end
    
    cms_import_db(local_db_config['migrator'],directory + "/domain.sql")

    # Activate the domain
    DomainModel.activate_domain(dmn.get_info)
  
    # Delete any rendered parts
    DomainModel.connection.execute("DELETE FROM site_template_rendered_parts WHERE 1")


    # Changed to local file storage
    DomainFile.update_all("processor='local'","file_type != 'fld' AND processor != 'local'")

    begin
      # Resave update any file store
      DomainFileInstance.rebuild_all
    rescue Exception => e
      puts("There was a problem rebuilding domain file instances - importing domain anyway")
    end

    
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

    unless Server.server_id.blank?
      DomainFile.update_all("server_id = #{Server.server_id}", 'file_type != "fld"')
      server_hash = DomainModel.generate_hash
      DomainFile.update_all "server_hash = '#{server_hash}'", 'file_type != "fld" and server_hash IS NULL'
    end

    PageRevision.find(:all,:conditions => { :active => 1, :revision_type => 'real' }, :include => :page_paragraphs).each { |rev| rev.page_paragraphs.map(&:save); rev.make_real }

    # Clear out the cache for the domain

    begin
      SiteFeature.find(:all).map(&:save)
      SiteTemplate.find(:all).map(&:save)
    rescue Exception => e
      puts("There was a problem resaving site templates and features - continuing import anyway")
    end

    # Resave paragraphs to fix links
    DataCache.expire_domain(dmn.database)
      
    # Make the database active again
    dmn.update_attributes(:active => true)
  end
end
