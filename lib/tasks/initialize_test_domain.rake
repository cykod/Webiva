namespace "cms" do
  desc "Initialize a Test Domain Database"
  task :initialize_test_domain => [:environment] do |t|
    domain = ENV['DOMAIN'] || 'test.dev'

    db_config_file = YAML.load_file("#{Rails.root}/config/cms_migrator.yml")
    db_config = db_config_file[Rails.env]
    db_adapter = db_config['adapter'] || 'mysql'
    db_socket = db_config['socket']
    db_encoding = db_config['encoding'] || 'utf8'
    db_host = db_config['host'] || 'localhost'

    ActiveRecord::Base.establish_connection(db_config)

    dmn = Client.first.domains.create :name => domain
    raise("Failed to create test domain: #{domain}") if dmn.new_record?
  
    base_name = db_config_file['base_webiva_db'] || "webiva"
    base_name += '_'
    dmn.database = base_name + sprintf("%03d",dmn.id) +  '_' + dmn.name.gsub(/[^a-zA-Z0-9]+/,"_")[0..20] 
    create_database = true

    dmn.status = 'working'
    dmn.save

    base_name = db_config_file['base_webiva_db_user'] || "cms"
    base_name += '_'
    migrator_name = base_name + dmn.id.to_s + "_m"
    migrator_password = Base64.encode64(Digest::SHA1.hexdigest("#{rand(1<<64)}/#{Time.now.to_f}/#{Process.pid}"))[0..7]
  
    if create_database
      dmn.update_attribute(:file_store, dmn.id)

      ActiveRecord::Base.connection.execute("CREATE DATABASE " + dmn.database)

      # Create the migrator user
      ActiveRecord::Base.connection.execute("GRANT ALL ON #{dmn.database}.* TO '#{migrator_name}'@'%' IDENTIFIED BY '#{migrator_password}'")
      ActiveRecord::Base.connection.execute("GRANT ALL ON #{dmn.database}.* TO '#{migrator_name}'@localhost IDENTIFIED BY '#{migrator_password}'")

      options = { 'production' => {
		      'adapter' => db_adapter,
		      'socket' => db_socket,
		      'database' => dmn.database,
		      'username' => migrator_name,
		      'password' => migrator_password,
		      'encoding' => db_encoding,
		      'file_store' => dmn.id,
		      'host' => db_host
		    },
		  'migrator' => {
		      'adapter' => db_adapter,
		      'socket' => db_socket,
		      'database' => dmn.database,
		      'username' => migrator_name,
		      'password' => migrator_password,
		      'encoding' => db_encoding,
		      'file_store' => dmn.id,
		      'host' => db_host
		    }
		}
		

      if dmn.domain_database
        dmn.domain_database.update_attributes :options => options, :name => dmn.database
      else
        dmn.create_domain_database :client_id => dmn.client_id, :name => dmn.database, :options => options
      end
      dmn.save

      ActiveRecord::Base.logger = Logger.new(STDOUT)
      ActiveRecord::Base.establish_connection(options['migrator'])
      
      DomainModel.activate_domain(dmn.get_info,'production')

      ActiveRecord::Migrator.migrate("#{Rails.root}/db/migrate/")

      ActiveRecord::Base.establish_connection(db_config)

      # And create any initial data as necessary
      Domain.initial_domain_data

      if ENV['INITIALIZER']
        cls = ENV['INITIALIZER'].constantize 
        cls.run_domain_initializer(dmn)
      end

      dmn.status = 'initialized'
      dmn.save
    end
  end
end
