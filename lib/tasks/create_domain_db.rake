
namespace "cms" do 
  desc "Initialize a Domain Database"
  task :create_domain_db => [:environment] do |t|
    domain_id = ENV['DOMAIN_ID'] || raise('Missing DOMAIN_ID=## argument')

    db_config_file = YAML.load_file("#{RAILS_ROOT}/config/cms_migrator.yml")
    db_config = db_config_file[ENV['RAILS_ENV']]
    db_adapter = db_config['adapter'] || 'mysql'
    db_socket = db_config['socket']
    db_encoding = db_config['encoding'] || 'utf8'
    db_host = db_config['host'] || 'localhost'

    ActiveRecord::Base.establish_connection(db_config)

    dmn = Domain.find_by_id_and_status(domain_id,'initializing') || raise("Invalid Domain ID: no domain with ID:#{domain_id} in the initializing state")
  
    if dmn.database.to_s.empty?
      dmn.database = 'webiva_' + sprintf("%03d",dmn.id) +  '_' + dmn.name.gsub(/[^a-zA-Z0-9]+/,"_")[0..20] 
      create_database = true
    end 
    dmn.status = 'working'
    dmn.save

    user_name = 'cms_' + dmn.id.to_s + "_user"
    migrator_name = 'cms_' + dmn.id.to_s + "_m"
    user_password =  Base64.encode64(Digest::SHA1.hexdigest("#{rand(1<<64)}/#{Time.now.to_f}/#{Process.pid}"))[0..7]
    migrator_password = Base64.encode64(Digest::SHA1.hexdigest("#{rand(1<<64)}/#{Time.now.to_f}/#{Process.pid}"))[0..7]
  
    if create_database
      dmn.update_attribute(:file_store,dmn.id)

      ActiveRecord::Base.connection.execute("CREATE DATABASE " + dmn.database)

      # Create the basic user
      ActiveRecord::Base.connection.execute("GRANT SELECT,INSERT,UPDATE,DELETE ON #{dmn.database}.* TO '#{user_name}'@'%' IDENTIFIED BY '#{user_password}'")
      ActiveRecord::Base.connection.execute("GRANT SELECT,INSERT,UPDATE,DELETE ON #{dmn.database}.* TO '#{user_name}'@localhost IDENTIFIED BY '#{user_password}'")
      # Create the migrator user
      ActiveRecord::Base.connection.execute("GRANT ALL ON #{dmn.database}.* TO '#{migrator_name}'@'%' IDENTIFIED BY '#{migrator_password}'")
      ActiveRecord::Base.connection.execute("GRANT ALL ON #{dmn.database}.* TO '#{migrator_name}'@localhost IDENTIFIED BY '#{migrator_password}'")

      options = { 'production' => {
		      'adapter' => db_adapter,
		      'socket' => db_socket,
		      'database' => dmn.database,
		      'username' => user_name,
		      'password' => user_password,
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
      ActiveRecord::Migrator.migrate("#{RAILS_ROOT}/db/migrate/")

      ActiveRecord::Base.establish_connection(db_config)

      # Now activate the DB connection to the created database
      DomainModel.activate_domain(dmn.get_info,'production')

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
